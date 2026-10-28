#include "cpp11.hpp"
#include "cpp11/matrix.hpp"
#include "cpp11/doubles.hpp"
#include "cpp11/list.hpp"
#include "cpp11/logicals.hpp"
#include "numeric_view.h"
#include <vector>
#include <algorithm>
#include <cmath>
#include <limits>

using namespace cpp11;
namespace writable = cpp11::writable;
using namespace std;

// Read each column's data pointer once. Constructing a cpp11 vector per cell
// costs a protection-list insertion, which dominated every kernel. Logical
// and integer columns are read in place, so neither R nor the kernel copies
// them.
struct row_data {
    std::vector<numeric_view> columns;
    R_xlen_t nrow = 0;
};

row_data row_columns(const list& tb)
{
    R_xlen_t ncol = tb.size();
    if (ncol == 0) stop("Select at least one column.");
    row_data data;
    data.columns.reserve(ncol);
    data.nrow = Rf_xlength(VECTOR_ELT(tb, 0));
    for (R_xlen_t j = 0; j < ncol; ++j) {
        SEXP column = VECTOR_ELT(tb, j);
        if (Rf_xlength(column) != data.nrow) stop("Row kernels require equal-length columns.");
        data.columns.emplace_back(column);
    }
    return data;
}

// Results need at least `minimum` observed values in the row and, with
// na.rm = FALSE, no missing value at all.
inline bool row_defined(size_t observed, size_t minimum, bool na_rm, size_t ncol)
{
    return observed >= minimum && (na_rm || observed == ncol);
}

// Allocate results independently of the input columns and skip missing values.
// Columns are visited in order, so ties keep the first observed value.
writable::doubles row_extreme(list tb, bool maximum)
{
    row_data data = row_columns(tb);
    const std::vector<numeric_view>& columns = data.columns;
    R_xlen_t nrow = data.nrow;
    writable::doubles out(nrow);
    double* best = REAL(out);
    std::vector<char> observed(nrow, 0);
    std::fill(best, best + nrow, NA_REAL);
    for (const numeric_view& column : columns) {
        for (R_xlen_t i = 0; i < nrow; ++i) {
            double value = column[i];
            if (std::isnan(value)) continue;
            if (!observed[i] || (maximum ? value > best[i] : value < best[i])) {
                best[i] = value;
                observed[i] = 1;
            }
        }
    }
    return out;
}

[[cpp11::register]] writable::doubles row_max_dbl(list tb)
{
    return row_extreme(tb, true);
}

[[cpp11::register]] writable::doubles row_min_dbl(list tb)
{
    return row_extreme(tb, false);
}

// Like rowSums(na.rm = TRUE) and rowMeans(na.rm = TRUE): accumulate column by
// column in long double and divide before rounding, so results are identical
// without first copying the columns into a matrix.
writable::doubles row_total(list tb, bool average, bool na_rm)
{
    row_data data = row_columns(tb);
    R_xlen_t nrow = data.nrow;
    std::vector<long double> total(nrow, 0.0L);
    std::vector<int> observed(nrow, 0);
    for (const numeric_view& column : data.columns) {
        for (R_xlen_t i = 0; i < nrow; ++i) {
            if (std::isnan(column[i])) continue;
            total[i] += column[i];
            ++observed[i];
        }
    }
    writable::doubles out(nrow);
    double* result = REAL(out);
    size_t minimum = average ? 1 : 0;
    for (R_xlen_t i = 0; i < nrow; ++i) {
        result[i] = row_defined(observed[i], minimum, na_rm, data.columns.size())
            ? static_cast<double>(average ? total[i] / observed[i] : total[i])
            : NA_REAL;
    }
    return out;
}

[[cpp11::register]] writable::doubles row_sum_dbl(list tb, bool na_rm)
{
    return row_total(tb, false, na_rm);
}

[[cpp11::register]] writable::doubles row_mean_dbl(list tb, bool na_rm)
{
    return row_total(tb, true, na_rm);
}

// Number of missing values in each row. Columns flagged in `masks` are
// already is.na() results; the others are logical, integer, double or
// character values.
[[cpp11::register]] writable::integers row_na_count(list tb, logicals masks)
{
    R_xlen_t ncol = tb.size();
    if (masks.size() != ncol) stop("Each column needs a mask flag.");
    R_xlen_t nrow = ncol ? Rf_xlength(VECTOR_ELT(tb, 0)) : 0;
    writable::integers out(nrow);
    int* count = INTEGER(out);
    std::fill(count, count + nrow, 0);
    for (R_xlen_t j = 0; j < ncol; ++j) {
        SEXP column = VECTOR_ELT(tb, j);
        if (Rf_xlength(column) != nrow) stop("Row kernels require equal-length columns.");
        bool mask = masks[j] == TRUE;
        if (mask && TYPEOF(column) == LGLSXP) {
            const int* values = LOGICAL_RO(column);
            for (R_xlen_t i = 0; i < nrow; ++i) count[i] += values[i] == 1;
        } else if (!mask && TYPEOF(column) == REALSXP) {
            const double* values = REAL_RO(column);
            for (R_xlen_t i = 0; i < nrow; ++i) count[i] += std::isnan(values[i]);
        } else if (!mask && (TYPEOF(column) == INTSXP || TYPEOF(column) == LGLSXP)) {
            const int* values = TYPEOF(column) == INTSXP ? INTEGER_RO(column) : LOGICAL_RO(column);
            for (R_xlen_t i = 0; i < nrow; ++i) count[i] += values[i] == NA_INTEGER;
        } else if (!mask && TYPEOF(column) == STRSXP) {
            for (R_xlen_t i = 0; i < nrow; ++i) count[i] += STRING_ELT(column, i) == NA_STRING;
        } else {
            stop("Unsupported column type for counting missing values.");
        }
    }
    return out;
}

// Sorting the observed values counts distinct values as an ordered set would:
// -0 and 0 are equal, and all missing values form one category.
[[cpp11::register]] writable::integers row_unique_dbl(list tb)
{
    row_data data = row_columns(tb);
    const std::vector<numeric_view>& columns = data.columns;
    R_xlen_t nrow = data.nrow;
    writable::integers out(nrow);
    int* counts = INTEGER(out);
    std::vector<double> values;
    values.reserve(columns.size());
    for (R_xlen_t i = 0; i < nrow; ++i) {
        values.clear();
        bool missing = false;
        for (const numeric_view& column : columns) {
            double value = column[i];
            if (std::isnan(value)) missing = true;
            else values.push_back(value);
        }
        std::sort(values.begin(), values.end());
        int distinct = values.empty() ? 0 : 1;
        for (size_t k = 1; k < values.size(); ++k) {
            if (values[k] != values[k - 1]) ++distinct;
        }
        counts[i] = distinct + (missing ? 1 : 0);
    }
    return out;
}

[[cpp11::register]] writable::doubles row_median_dbl(list tb, bool na_rm)
{
    row_data data = row_columns(tb);
    const std::vector<numeric_view>& columns = data.columns;
    R_xlen_t nrow = data.nrow;
    writable::doubles out(nrow);
    double* median = REAL(out);
    std::vector<double> values;
    values.reserve(columns.size());
    for (R_xlen_t i = 0; i < nrow; ++i) {
        values.clear();
        for (const numeric_view& column : columns) {
            if (!std::isnan(column[i])) values.push_back(column[i]);
        }
        if (!row_defined(values.size(), 1, na_rm, columns.size())) {
            median[i] = NA_REAL;
            continue;
        }
        size_t middle = values.size() / 2;
        std::nth_element(values.begin(), values.begin() + middle, values.end());
        double upper = values[middle];
        if (values.size() % 2) {
            median[i] = upper;
        } else {
            double lower = *std::max_element(values.begin(), values.begin() + middle);
            // Avoid overflow of two finite endpoints, without underflowing
            // small endpoints unnecessarily. Opposing infinities remain NaN.
            double threshold = std::numeric_limits<double>::max() / 2;
            median[i] = std::isfinite(lower) && std::isfinite(upper) &&
                (std::abs(lower) > threshold || std::abs(upper) > threshold)
                ? lower / 2 + upper / 2 : (lower + upper) / 2;
        }
    }
    return out;
}

writable::doubles row_dispersion(list tb, bool standard_deviation, bool na_rm)
{
    row_data data = row_columns(tb);
    const std::vector<numeric_view>& columns = data.columns;
    R_xlen_t nrow = data.nrow;
    writable::doubles out(nrow);
    double* result = REAL(out);
    std::vector<double> values;
    values.reserve(columns.size());
    for (R_xlen_t i = 0; i < nrow; ++i) {
        values.clear();
        bool finite = true;
        double largest = 0;
        for (const numeric_view& column : columns) {
            double value = column[i];
            if (std::isnan(value)) continue;
            values.push_back(value);
            finite = finite && std::isfinite(value);
            largest = std::max(largest, std::abs(value));
        }
        if (!row_defined(values.size(), 2, na_rm, columns.size())) {
            result[i] = NA_REAL;
            continue;
        }
        if (!finite) {
            result[i] = R_NaN;
            continue;
        }
        // Shift before centering to preserve small differences at large
        // offsets. Halve extreme values so subtraction is safe even on
        // platforms where long double has the same range as double.
        long double factor = largest > std::numeric_limits<double>::max() / 2 ? 2 : 1;
        long double origin = static_cast<long double>(values[0]) / factor;
        long double center = 0;
        for (double value : values) {
            center += (static_cast<long double>(value) / factor - origin) / values.size();
        }
        long double scale = 0;
        for (double value : values) {
            long double delta = static_cast<long double>(value) / factor - origin - center;
            scale = std::max(scale, std::abs(delta));
        }
        if (scale == 0) {
            result[i] = 0;
            continue;
        }
        long double squares = 0;
        long double correction = 0;
        for (double value : values) {
            long double delta = (static_cast<long double>(value) / factor - origin - center) / scale;
            squares += delta * delta;
            correction += delta;
        }
        long double normalized = std::max(static_cast<long double>(0),
            (squares - correction * correction / values.size()) / (values.size() - 1));
        // Square the scale rather than the rounded square root, so variances
        // stay exact where long double is no wider than double (arm64, noLD).
        result[i] = static_cast<double>(standard_deviation
            ? scale * std::sqrt(normalized) * factor
            : scale * scale * normalized * factor * factor);
    }
    return out;
}

[[cpp11::register]] writable::doubles row_var_dbl(list tb, bool na_rm)
{
    return row_dispersion(tb, false, na_rm);
}

[[cpp11::register]] writable::doubles row_sd_dbl(list tb, bool na_rm)
{
    return row_dispersion(tb, true, na_rm);
}
