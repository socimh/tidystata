#include "cpp11.hpp"
#include "cpp11/doubles.hpp"
#include "cpp11/integers.hpp"
#include "cpp11/list.hpp"
#include <algorithm>
#include <cfloat>
#include <cmath>
#include <vector>

using namespace cpp11;
namespace writable = cpp11::writable;

// Sums and cumulative sums over the 1-based row locations of each group.
// Both accumulate in long double in location order, as base sum() and
// cumsum() do, so each group's result is identical to calling them on
// x[loc] without allocating one subset per group.

SEXP group_locations(const list& locs, R_xlen_t g)
{
    SEXP loc = VECTOR_ELT(locs, g);
    if (TYPEOF(loc) != INTSXP) stop("Group locations must be integer vectors.");
    return loc;
}

[[cpp11::register]] writable::doubles group_sum_dbl(doubles x, list locs)
{
    const double* values = REAL_RO(x);
    R_xlen_t groups = locs.size();
    writable::doubles out(groups);
    double* result = REAL(out);
    for (R_xlen_t g = 0; g < groups; ++g) {
        SEXP loc = group_locations(locs, g);
        const int* rows = INTEGER_RO(loc);
        R_xlen_t size = Rf_xlength(loc);
        long double total = 0.0L;
        for (R_xlen_t k = 0; k < size; ++k) {
            total += values[rows[k] - 1];
        }
        result[g] = total > DBL_MAX ? R_PosInf :
            total < -DBL_MAX ? R_NegInf : static_cast<double>(total);
    }
    return out;
}

// As mean() on doubles: a long double mean, recomputed from smaller terms
// if the total overflows, then refined by the mean residual.
[[cpp11::register]] writable::doubles group_mean_dbl(doubles x, list locs)
{
    const double* values = REAL_RO(x);
    R_xlen_t groups = locs.size();
    writable::doubles out(groups);
    double* result = REAL(out);
    for (R_xlen_t g = 0; g < groups; ++g) {
        SEXP loc = group_locations(locs, g);
        const int* rows = INTEGER_RO(loc);
        R_xlen_t size = Rf_xlength(loc);
        long double total = 0.0L;
        for (R_xlen_t k = 0; k < size; ++k) {
            total += values[rows[k] - 1];
        }
        if (R_FINITE(static_cast<double>(total))) {
            total /= size;
        } else {
            long double scaled = 0.0L;
            for (R_xlen_t k = 0; k < size; ++k) {
                scaled += values[rows[k] - 1] / size;
            }
            total = scaled;
        }
        if (R_FINITE(static_cast<double>(total))) {
            long double residual = 0.0L;
            for (R_xlen_t k = 0; k < size; ++k) {
                residual += values[rows[k] - 1] - total;
            }
            total += residual / size;
        }
        result[g] = static_cast<double>(total);
    }
    return out;
}

[[cpp11::register]] writable::doubles group_cumsum_dbl(doubles x, list locs)
{
    const double* values = REAL_RO(x);
    R_xlen_t n = x.size();
    writable::doubles out(n);
    double* result = REAL(out);
    std::fill(result, result + n, NA_REAL);
    for (R_xlen_t g = 0; g < locs.size(); ++g) {
        SEXP loc = group_locations(locs, g);
        const int* rows = INTEGER_RO(loc);
        R_xlen_t size = Rf_xlength(loc);
        // As cumsum(): once an NA appears, the rest is NA; a NaN input gives
        // R's NaN until any later NA. Other values accumulate.
        long double total = 0.0L;
        bool na = false;
        bool nan = false;
        for (R_xlen_t k = 0; k < size; ++k) {
            double value = values[rows[k] - 1];
            double& cumulative = result[rows[k] - 1];
            if (na || R_IsNA(value)) {
                na = true;
                cumulative = NA_REAL;
            } else if (nan || std::isnan(value)) {
                nan = true;
                cumulative = R_NaN;
            } else {
                total += value;
                cumulative = static_cast<double>(total);
            }
        }
    }
    return out;
}

// The kernels below take values already arranged in contiguous segments, one
// per group, with `sizes` giving each segment's length.

const int* segment_sizes(const doubles& values, const integers& sizes)
{
    const int* n = INTEGER_RO(sizes);
    R_xlen_t total = 0;
    for (R_xlen_t g = 0; g < sizes.size(); ++g) {
        if (n[g] == NA_INTEGER || n[g] < 0) stop("Group sizes must be nonnegative.");
        total += n[g];
    }
    if (total != values.size()) stop("Group sizes must add up to the number of values.");
    return n;
}

// As min() or max() of each segment: R's rmin()/rmax() scan, where any NA
// trumps NaN, then the combination with the +Inf or -Inf starting value.
// Empty segments give NA, as summ() reports them.
writable::doubles group_extreme(doubles values, integers sizes, bool maximum)
{
    const double* x = REAL_RO(values);
    const int* n = segment_sizes(values, sizes);
    writable::doubles out(sizes.size());
    double* result = REAL(out);
    R_xlen_t start = 0;
    for (R_xlen_t g = 0; g < sizes.size(); ++g) {
        double s = 0.0;
        bool updated = false;
        for (R_xlen_t k = start; k < start + n[g]; ++k) {
            if (ISNAN(x[k])) {
                if (!ISNA(s)) s = x[k];
                updated = true;
            } else if (!updated || (maximum ? x[k] > s : x[k] < s)) {
                s = x[k];
                updated = true;
            }
        }
        double cumulative = maximum ? R_NegInf : R_PosInf;
        if (!updated) {
            cumulative = NA_REAL;
        } else if (ISNAN(s)) {
            if (ISNA(s)) cumulative = s;
            else cumulative += s;
        } else if (maximum ? s > cumulative : s < cumulative) {
            cumulative = s;
        }
        result[g] = cumulative;
        start += n[g];
    }
    return out;
}

[[cpp11::register]] writable::doubles group_min_dbl(doubles values, integers sizes)
{
    return group_extreme(values, sizes, false);
}

[[cpp11::register]] writable::doubles group_max_dbl(doubles values, integers sizes)
{
    return group_extreme(values, sizes, true);
}

// As var() of each segment with NAs propagated (R's cov_na_1() in cov.c): a
// two-pass long double mean rounded to double, then long double squared
// deviations divided by n - 1. Segments with fewer than two values, or with
// any NA or NaN, give NA.
[[cpp11::register]] writable::doubles group_var_dbl(doubles values, integers sizes)
{
    const double* x = REAL_RO(values);
    const int* n = segment_sizes(values, sizes);
    writable::doubles out(sizes.size());
    double* result = REAL(out);
    R_xlen_t start = 0;
    for (R_xlen_t g = 0; g < sizes.size(); ++g) {
        const double* xx = x + start;
        R_xlen_t size = n[g];
        start += size;
        bool has_na = false;
        for (R_xlen_t k = 0; k < size; ++k) {
            if (ISNAN(xx[k])) {
                has_na = true;
                break;
            }
        }
        if (size <= 1 || has_na) {
            result[g] = NA_REAL;
            continue;
        }
        long double sum = 0.0L;
        for (R_xlen_t k = 0; k < size; ++k) sum += xx[k];
        long double tmp = sum / size;
        if (R_FINITE(static_cast<double>(tmp))) {
            sum = 0.0L;
            for (R_xlen_t k = 0; k < size; ++k) sum += (xx[k] - tmp);
            tmp = tmp + sum / size;
        }
        long double xxm = static_cast<double>(tmp);
        sum = 0.0L;
        for (R_xlen_t k = 0; k < size; ++k) {
            sum += static_cast<long double>(xx[k] - xxm) * (xx[k] - xxm);
        }
        result[g] = static_cast<double>(sum / (size - 1));
    }
    return out;
}

// Stata's weighted percentiles, as weighted_quantile() in R/weights.R, for
// each segment sorted by value (stable, so ties keep row order). Values with
// zero weight are dropped; cumulative weights round a long double running sum
// as cumsum() does. Column j of the result holds probability j.
[[cpp11::register]] writable::doubles group_weighted_quantile_dbl(
    doubles values, doubles weights, integers sizes, doubles probs)
{
    const double* x = REAL_RO(values);
    const double* w = REAL_RO(weights);
    const int* n = segment_sizes(values, sizes);
    if (weights.size() != values.size()) stop("Weights must match the values.");
    const double* p = REAL_RO(probs);
    R_xlen_t groups = sizes.size();
    R_xlen_t nprob = probs.size();
    writable::doubles out(groups * nprob);
    double* result = REAL(out);
    std::vector<double> kept;
    std::vector<double> cumulative;
    const double epsilon = std::sqrt(DBL_EPSILON);
    R_xlen_t start = 0;
    for (R_xlen_t g = 0; g < groups; ++g) {
        kept.clear();
        cumulative.clear();
        long double running = 0.0L;
        for (R_xlen_t k = start; k < start + n[g]; ++k) {
            if (!(w[k] > 0)) continue;
            kept.push_back(x[k]);
            running += w[k];
            cumulative.push_back(static_cast<double>(running));
        }
        start += n[g];
        R_xlen_t size = kept.size();
        for (R_xlen_t j = 0; j < nprob; ++j) {
            double& q = result[g + j * groups];
            if (size == 0) {
                q = NA_REAL;
                continue;
            }
            if (p[j] <= 0) {
                q = kept[0];
                continue;
            }
            if (p[j] >= 1) {
                q = kept[size - 1];
                continue;
            }
            double total = cumulative[size - 1];
            double target = p[j] * total;
            double tolerance = epsilon * total;
            R_xlen_t exact = -1;
            for (R_xlen_t i = 0; i < size; ++i) {
                if (std::fabs(cumulative[i] - target) <= tolerance) {
                    exact = i;
                    break;
                }
            }
            if (exact >= 0 && exact < size - 1) {
                q = (kept[exact] + kept[exact + 1]) / 2;
                continue;
            }
            R_xlen_t above = -1;
            for (R_xlen_t i = 0; i < size; ++i) {
                if (cumulative[i] > target) {
                    above = i;
                    break;
                }
            }
            if (above < 0) stop("subscript out of bounds");
            q = kept[above];
        }
    }
    return out;
}
