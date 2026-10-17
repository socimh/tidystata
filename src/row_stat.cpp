#include "cpp11.hpp"
#include "cpp11/matrix.hpp"
#include "cpp11/doubles.hpp"
#include <vector>
#include <set>
#include <algorithm>
#include <unordered_set>
#include <iostream>
#include <numeric>
#include <random>
#include <cmath>
#include <limits>

using namespace cpp11;
namespace writable = cpp11::writable;
using namespace std;

[[cpp11::register]] cpp11::doubles_matrix<> df_to_mat(data_frame tb, double na)
{
    int nrow = tb.nrow();
    int ncol = tb.size();
    writable::doubles col;
    writable::doubles_matrix<> mat(nrow, ncol);

    for (int i = 0; i < ncol; i++)
    {
        col = tb[i];
        for (int j = 0; j < nrow; j++)
        {
            double val = col[j];
            if (std::isnan(val))
            {
                mat(j, i) = na;
            }
            else
            {
                mat(j, i) = val;
            }
        }
    }

    return mat;
}

// Allocate results independently of the input columns and skip missing values.
writable::doubles row_extreme(data_frame tb, bool maximum)
{
    if (tb.size() == 0) stop("Select at least one column.");
    int nrow = tb.nrow();
    writable::doubles out(nrow);
    for (int i = 0; i < nrow; ++i) {
        double best = NA_REAL;
        bool observed = false;
        for (int j = 0; j < tb.size(); ++j) {
            doubles col = tb[j];
            double value = col[i];
            if (std::isnan(value)) continue;
            if (!observed || (maximum ? value > best : value < best)) {
                best = value;
                observed = true;
            }
        }
        out[i] = best;
    }
    return out;
}

[[cpp11::register]] writable::doubles row_max_dbl(data_frame tb)
{
    return row_extreme(tb, true);
}

[[cpp11::register]] writable::doubles row_min_dbl(data_frame tb)
{
    return row_extreme(tb, false);
}

writable::doubles row_total(data_frame tb, bool average)
{
    if (tb.size() == 0) stop("Select at least one column.");
    int nrow = tb.nrow();
    writable::doubles out(nrow);
    for (int i = 0; i < nrow; ++i) {
        double total = 0;
        int observed = 0;
        for (int j = 0; j < tb.size(); ++j) {
            doubles col = tb[j];
            if (std::isnan(col[i])) continue;
            total += col[i];
            ++observed;
        }
        out[i] = average ? (observed ? total / observed : NA_REAL) : total;
    }
    return out;
}

[[cpp11::register]] writable::doubles row_sum_dbl(data_frame tb)
{
    return row_total(tb, false);
}

[[cpp11::register]] writable::doubles row_mean_dbl(data_frame tb)
{
    return row_total(tb, true);
}

[[cpp11::register]] writable::integers row_unique_dbl(data_frame tb)
{
    if (tb.size() == 0) stop("Select at least one column.");
    int nrow = tb.nrow();
    writable::integers out(nrow);
    for (int i = 0; i < nrow; ++i) {
        std::set<double> values;
        bool missing = false;
        for (int j = 0; j < tb.size(); ++j) {
            doubles col = tb[j];
            double value = col[i];
            if (std::isnan(value)) missing = true;
            else values.insert(value);
        }
        out[i] = static_cast<int>(values.size()) + (missing ? 1 : 0);
    }
    return out;
}

[[cpp11::register]] writable::doubles row_median_dbl(data_frame tb)
{
    if (tb.size() == 0) stop("Select at least one column.");
    writable::doubles out(tb.nrow());
    std::vector<double> values;
    values.reserve(tb.size());
    for (int i = 0; i < tb.nrow(); ++i) {
        values.clear();
        for (int j = 0; j < tb.size(); ++j) {
            doubles col = tb[j];
            if (!std::isnan(col[i])) values.push_back(col[i]);
        }
        if (values.empty()) {
            out[i] = NA_REAL;
            continue;
        }
        size_t middle = values.size() / 2;
        std::nth_element(values.begin(), values.begin() + middle, values.end());
        double upper = values[middle];
        if (values.size() % 2) {
            out[i] = upper;
        } else {
            double lower = *std::max_element(values.begin(), values.begin() + middle);
            // Avoid overflow of two finite endpoints, without underflowing
            // small endpoints unnecessarily. Opposing infinities remain NaN.
            double threshold = std::numeric_limits<double>::max() / 2;
            out[i] = std::isfinite(lower) && std::isfinite(upper) &&
                (std::abs(lower) > threshold || std::abs(upper) > threshold)
                ? lower / 2 + upper / 2 : (lower + upper) / 2;
        }
    }
    return out;
}

writable::doubles row_dispersion(data_frame tb, bool standard_deviation)
{
    if (tb.size() == 0) stop("Select at least one column.");
    writable::doubles out(tb.nrow());
    std::vector<double> values;
    values.reserve(tb.size());
    for (int i = 0; i < tb.nrow(); ++i) {
        values.clear();
        bool finite = true;
        double largest = 0;
        for (int j = 0; j < tb.size(); ++j) {
            doubles col = tb[j];
            double value = col[i];
            if (std::isnan(value)) continue;
            values.push_back(value);
            finite = finite && std::isfinite(value);
            largest = std::max(largest, std::abs(value));
        }
        if (values.size() < 2) {
            out[i] = NA_REAL;
            continue;
        }
        if (!finite) {
            out[i] = R_NaN;
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
            out[i] = 0;
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
        long double sd = scale * std::sqrt(normalized) * factor;
        out[i] = static_cast<double>(standard_deviation ? sd : sd * sd);
    }
    return out;
}

[[cpp11::register]] writable::doubles row_var_dbl(data_frame tb)
{
    return row_dispersion(tb, false);
}

[[cpp11::register]] writable::doubles row_sd_dbl(data_frame tb)
{
    return row_dispersion(tb, true);
}
