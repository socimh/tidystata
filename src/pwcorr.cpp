#include "cpp11.hpp"
#include "cpp11/doubles.hpp"
#include "cpp11/list.hpp"
#include "numeric_view.h"
#include "r_math.h"
#include <Rmath.h>
#include <algorithm>
#include <cfloat>
#include <cmath>
#include <numeric>
#include <vector>

using namespace cpp11;
namespace writable = cpp11::writable;

namespace {

// Each helper below reproduces the R function named in its comment, including
// its accumulation order and extended precision, so results are identical.

// sum(): extended-precision accumulation, overflowing to infinity.
double pwcorr_sum(long double total)
{
    return total > DBL_MAX ? R_PosInf : total < -DBL_MAX ? R_NegInf : static_cast<double>(total);
}

template <typename Values>
double pwcorr_sum_of(const Values& x, size_t n)
{
    long double total = 0;
    for (size_t i = 0; i < n; ++i) total += x[i];
    return pwcorr_sum(total);
}

// The two-pass mean of mean() and cor(): an extended-precision mean refined
// by the mean residual while it is finite.
template <typename Values>
double pwcorr_mean(const Values& x, const std::vector<R_xlen_t>& rows)
{
    const R_xlen_t n = rows.size();
    long double total = 0;
    for (R_xlen_t row : rows) total += x[row];
    long double mean = total / n;
    if (R_FINITE(static_cast<double>(mean))) {
        total = 0;
        for (R_xlen_t row : rows) total += x[row] - mean;
        mean += total / n;
    }
    return static_cast<double>(mean);
}

// cor(x, y, use = "complete.obs") on the given rows, with the arithmetic of
// R's cov_complete2(): rounded means, extended-precision deviations and
// sums, and the clamp to [-1, 1].
template <typename Values>
double pwcorr_complete(const Values& x, const Values& y, const std::vector<R_xlen_t>& rows)
{
    const long double mx = pwcorr_mean(x, rows);
    const long double my = pwcorr_mean(y, rows);
    const R_xlen_t n1 = rows.size() - 1;
    long double xy = 0, xx = 0, yy = 0;
    for (R_xlen_t row : rows) {
        const long double dx = x[row] - mx;
        const long double dy = y[row] - my;
        xy += dx * dy;
        xx += dx * dx;
        yy += dy * dy;
    }
    const double sx = static_cast<double>(std::sqrt(xx / n1));
    const double sy = static_cast<double>(std::sqrt(yy / n1));
    if (sx == 0 || sy == 0) return NA_REAL;
    double r = static_cast<double>(xy / n1);
    r /= sx * sy;
    return r >= 1 ? 1 : r <= -1 ? -1 : r;
}

// Anchor subtraction preserves nearby gaps; opposite finite extremes that
// overflow the subtraction are scaled first. Mirrors pwcorr_rescale().
void pwcorr_rescale(std::vector<double>& x)
{
    bool finite = true;
    for (double value : x) finite = finite && std::isfinite(value);
    const double anchor = x[0];
    bool overflow = false;
    for (double value : x) overflow = overflow || !std::isfinite(value - anchor);
    if (finite && overflow) {
        double largest = 0;
        for (double value : x) largest = std::max(largest, std::fabs(value));
        for (double& value : x) value /= largest;
    }
    const double origin = x[0];
    double scale = 0;
    bool defined = true;
    for (double& value : x) {
        value -= origin;
        if (std::isnan(value)) defined = false;
        else scale = std::max(scale, std::fabs(value));
    }
    if (defined && std::isfinite(scale) && scale > 0) {
        for (double& value : x) value /= scale;
    }
}

// The weighted correlation of pwcorr_pair() over complete rows with positive
// weights, keeping the order and rounding of its vectorised arithmetic.
double pwcorr_weighted(const numeric_view& x, const numeric_view& y, const double* w,
                       const std::vector<R_xlen_t>& rows,
                       std::vector<double>& wx, std::vector<double>& xs,
                       std::vector<double>& ys)
{
    // R's separate vector operations round before accumulation. ARM Clang
    // otherwise fuses products and additions, changing r and its p-value.
#if defined(__clang__)
#pragma clang fp contract(off)
#endif
    wx.clear();
    xs.clear();
    ys.clear();
    double largest = 0;
    for (R_xlen_t row : rows) {
        if (!(w[row] > 0)) continue;
        largest = std::max(largest, w[row]);
        wx.push_back(w[row]);
        xs.push_back(x[row]);
        ys.push_back(y[row]);
    }
    if (wx.empty()) return NA_REAL;
    for (double& value : wx) value /= largest;
    pwcorr_rescale(xs);
    pwcorr_rescale(ys);
    long double total_sum = 0, x_sum = 0, y_sum = 0;
    for (size_t i = 0; i < wx.size(); ++i) {
        total_sum += wx[i];
        x_sum += wx[i] * xs[i];
        y_sum += wx[i] * ys[i];
    }
    const double total = pwcorr_sum(total_sum);
    const double mx = pwcorr_sum(x_sum) / total;
    const double my = pwcorr_sum(y_sum) / total;
    long double xy = 0, xx = 0, yy = 0;
    for (size_t i = 0; i < wx.size(); ++i) {
        const double dx = xs[i] - mx;
        const double dy = ys[i] - my;
        xy += wx[i] * dx * dy;
        xx += wx[i] * (dx * dx);
        yy += wx[i] * (dy * dy);
    }
    return pwcorr_sum(xy) / r_sqrt(pwcorr_sum(xx)) / r_sqrt(pwcorr_sum(yy));
}

// rank(x): average ranks of tied values, as (i + j + 2) / 2.
void pwcorr_rank(const std::vector<double>& x, std::vector<double>& ranks,
                 std::vector<R_xlen_t>& order)
{
    const size_t n = x.size();
    order.resize(n);
    std::iota(order.begin(), order.end(), 0);
    std::stable_sort(order.begin(), order.end(),
                     [&](R_xlen_t a, R_xlen_t b) { return x[a] < x[b]; });
    ranks.resize(n);
    for (size_t i = 0, j; i < n; i = j + 1) {
        j = i;
        while (j + 1 < n && x[order[j]] == x[order[j + 1]]) ++j;
        for (size_t k = i; k <= j; ++k) ranks[order[k]] = (i + j + 2) / 2.;
    }
}

// The rank-only quantities of spearman_power_sums() after spearman_beta_fit()
// has centered the ranks.
struct spearman_sums {
    double mean, sd2, x3, x4, x2x, xxx, x3x, x2x2, x2xx, xxxx;
};

struct spearman_scratch {
    std::vector<double> sorted, s1, s2, s3, xx, x2x, xxx, term;
    std::vector<R_xlen_t> rows;
};

// cumsum() of term into out: an extended-precision running sum, rounded at
// each element.
void pwcorr_cumsum(const std::vector<double>& term, std::vector<double>& out)
{
    out.resize(term.size());
    long double total = 0;
    for (size_t i = 0; i < term.size(); ++i) {
        total += term[i];
        out[i] = static_cast<double>(total);
    }
}

spearman_sums spearman_power_sums(const std::vector<double>& centered, spearman_scratch& s)
{
    std::vector<double>& x = s.sorted;
    x.assign(centered.begin(), centered.end());
    std::sort(x.begin(), x.end());
    const size_t n = x.size();
    s.rows.resize(n);
    std::iota(s.rows.begin(), s.rows.end(), 0);
    spearman_sums out;
    out.mean = pwcorr_mean(x, s.rows);
    // var(): cov()'s two-pass mean and extended-precision squared deviations.
    {
        const long double mean = out.mean;
        long double total = 0;
        for (double value : x) total += (value - mean) * (value - mean);
        out.sd2 = static_cast<double>(total / (n - 1));
    }
    {
        // These terms correspond to separate R vector operations. Keep the
        // native var() loop above on the compiler's default arithmetic path.
#if defined(__clang__)
#pragma clang fp contract(off)
#endif
        auto lag = [](const std::vector<double>& v, size_t i) { return i ? v[i - 1] : 0.0; };
        std::vector<double>& term = s.term;
        term.resize(n);
        pwcorr_cumsum(x, s.s1);
        for (size_t i = 0; i < n; ++i) term[i] = x[i] * x[i];
        pwcorr_cumsum(term, s.s2);
        for (size_t i = 0; i < n; ++i) term[i] = R_pow(x[i], 3);
        pwcorr_cumsum(term, s.s3);
        out.x3 = pwcorr_sum_of(term, n);
        for (size_t i = 0; i < n; ++i) term[i] = x[i] * lag(s.s1, i);
        pwcorr_cumsum(term, s.xx);
        for (size_t i = 0; i < n; ++i) term[i] = x[i] * (lag(s.s2, i) + x[i] * lag(s.s1, i));
        pwcorr_cumsum(term, s.x2x);
        for (size_t i = 0; i < n; ++i) term[i] = x[i] * lag(s.xx, i);
        pwcorr_cumsum(term, s.xxx);
        for (size_t i = 0; i < n; ++i) term[i] = R_pow(x[i], 4);
        out.x4 = pwcorr_sum_of(term, n);
        out.x2x = s.x2x[n - 1];
        out.xxx = s.xxx[n - 1];
        for (size_t i = 0; i < n; ++i) term[i] = x[i] * (lag(s.s3, i) + x[i] * x[i] * lag(s.s1, i));
        out.x3x = pwcorr_sum_of(term, n);
        for (size_t i = 0; i < n; ++i) term[i] = x[i] * x[i] * lag(s.s2, i);
        out.x2x2 = pwcorr_sum_of(term, n);
        for (size_t i = 0; i < n; ++i) term[i] = x[i] * (lag(s.x2x, i) + x[i] * lag(s.xx, i));
        out.x2xx = pwcorr_sum_of(term, n);
        for (size_t i = 0; i < n; ++i) term[i] = x[i] * lag(s.xxx, i);
        out.xxxx = pwcorr_sum_of(term, n);
        return out;
    }
}

// center() of spearman_beta_fit(): subtract the mean, or its integer part.
void spearman_center(const std::vector<double>& ranks, std::vector<double>& out,
                     spearman_scratch& s)
{
    s.rows.resize(ranks.size());
    std::iota(s.rows.begin(), s.rows.end(), 0);
    const double mean = pwcorr_mean(ranks, s.rows);
    const double shift = std::fabs(mean) < 1 ? mean : std::trunc(mean);
    out.resize(ranks.size());
    for (size_t i = 0; i < ranks.size(); ++i) out[i] = ranks[i] - shift;
}

// min() and max() return NaN when either argument is.
double pwcorr_min(double a, double b) { return ISNAN(a) || ISNAN(b) ? a + b : std::min(a, b); }
double pwcorr_max(double a, double b) { return ISNAN(a) || ISNAN(b) ? a + b : std::max(a, b); }

// spearman_p(): Stata's beta fit to the permutation moments of the centered
// ranks, or a normal approximation without a valid fit.
double spearman_p(const std::vector<double>& cx, const std::vector<double>& cy,
                  const spearman_sums& sx, const spearman_sums& sy, double rho)
{
    // Preserve the intermediate rounding of the R reference expressions.
#if defined(__clang__)
#pragma clang fp contract(off)
#endif
    const double n = cx.size();
    double lower = NA_REAL, upper = NA_REAL;
    bool fitted = false;
    if (cx.size() >= 4) {
        const double m1 = n * sx.mean * sy.mean;
        const double m2 = (n - 1) * sx.sd2 * sy.sd2;
        const double m3 = (sx.x3 * sy.x3 +
            (3 * sx.x2x * sy.x2x + 36 * sx.xxx * sy.xxx / (n - 2)) / (n - 1)) / n -
            3 * m1 * m2 - R_pow(m1, 3);
        const double m4 = (sx.x4 * sy.x4 +
            (4 * sx.x3x * sy.x3x + 12 * sx.x2x2 * sy.x2x2 +
             (24 * sx.x2xx * sy.x2xx + 576 * sx.xxxx * sy.xxxx / (n - 3)) / (n - 2)) /
            (n - 1)) / n -
            4 * m1 * m3 - 6 * (m1 * m1) * m2 - R_pow(m1, 4);
        const double g3 = m3 / R_pow(r_sqrt(m2), 3);
        const double g4 = m4 / (m2 * m2);
        const double r = 6 * (g4 - g3 * g3 - 1) / (6 + 3 * (g3 * g3) - 2 * g4);
        double d = 1 - 24 * (r + 1) / ((r + 2) * (r + 3) * g4 - 3 * (r - 6) * (r + 1));
        d = r_sqrt(pwcorr_max(d, 0));
        const double half = r / 2;
        const double alpha = half * (g3 > 0 ? 1 - d : 1 + d);
        const double beta = half * (g3 > 0 ? 1 + d : 1 - d);
        if (!ISNAN(alpha) && !ISNAN(beta) && alpha > 0 && beta > 0) {
            long double shape_sum = 0, shape_prod = 1;
            shape_sum += alpha;
            shape_sum += beta;
            shape_prod *= alpha;
            shape_prod *= beta;
            const double e = r_sqrt(m2 * (pwcorr_sum(shape_sum) + 1) / pwcorr_sum(shape_prod));
            const double low = m1 - alpha * e;
            const double high = m1 + beta * e;
            if (std::isfinite(low) && std::isfinite(high) && low < high) {
                long double cross = 0;
                for (size_t i = 0; i < cx.size(); ++i) cross += cx[i] * cy[i];
                const double stat = (pwcorr_sum(cross) - low) / (high - low);
                lower = Rf_pbeta(stat, alpha, beta, 1, 0);
                upper = Rf_pbeta(stat, alpha, beta, 0, 0);
                fitted = true;
            }
        }
    }
    if (!fitted) {
        const double statistic = r_sqrt(n - 1) * rho;
        lower = Rf_pnorm5(statistic, 0, 1, 1, 0);
        upper = Rf_pnorm5(-statistic, 0, 1, 1, 0);
    }
    return pwcorr_min(1, 2 * pwcorr_min(lower, upper));
}

// Ranks, centered ranks and power sums of one column, reused by every pair
// in which the column has all rows. Power sums are filled on first use.
struct spearman_column {
    std::vector<double> ranks, centered;
    spearman_sums sums;
    bool ready = false, summed = false;
};

// The common length of the correlated columns.
R_xlen_t pwcorr_rows(const list& columns)
{
    const R_xlen_t nrow = columns.size() ? Rf_xlength(VECTOR_ELT(columns, 0)) : 0;
    for (R_xlen_t j = 0; j < columns.size(); ++j) {
        if (Rf_xlength(VECTOR_ELT(columns, j)) != nrow) {
            stop("Correlation columns must have equal length.");
        }
    }
    return nrow;
}

} // namespace

// Pearson correlations and sample sizes for every pair of columns, in the
// order of combn(): (1, 2), (1, 3), ..., (2, 3), .... Each pair uses its own
// complete rows, found without allocating a row mask per pair. Logical,
// integer and double columns are read in place. With weights, `n` is the
// summed weight (frequency) or the complete-row count (analytic).
[[cpp11::register]] writable::list pwcorr_pearson(list columns, SEXP weights, bool frequency)
{
    const R_xlen_t nrow = pwcorr_rows(columns);
    const R_xlen_t p = columns.size();
    std::vector<numeric_view> values;
    values.reserve(p);
    for (R_xlen_t j = 0; j < p; ++j) values.emplace_back(VECTOR_ELT(columns, j));
    const bool weighted = weights != R_NilValue;
    if (weighted && (TYPEOF(weights) != REALSXP || Rf_xlength(weights) != nrow)) {
        stop("Weights must be a double vector with one value per row.");
    }
    const double* w = weighted ? REAL_RO(weights) : nullptr;
    const R_xlen_t pairs = p * (p - 1) / 2;
    writable::doubles r(pairs), n(pairs);
    std::vector<R_xlen_t> rows;
    rows.reserve(nrow);
    std::vector<double> wx, xs, ys;
    R_xlen_t k = 0;
    for (R_xlen_t i = 0; i < p; ++i) {
        for (R_xlen_t j = i + 1; j < p; ++j, ++k) {
            check_user_interrupt();
            const numeric_view& x = values[i];
            const numeric_view& y = values[j];
            rows.clear();
            for (R_xlen_t row = 0; row < nrow; ++row) {
                if (!ISNAN(x[row]) && !ISNAN(y[row])) rows.push_back(row);
            }
            double result;
            if (!weighted) {
                n[k] = rows.size();
                result = rows.size() > 1 ? pwcorr_complete(x, y, rows) : NA_REAL;
            } else {
                if (frequency) {
                    long double total = 0;
                    for (R_xlen_t row : rows) total += w[row];
                    n[k] = pwcorr_sum(total);
                } else {
                    n[k] = rows.size();
                }
                result = pwcorr_weighted(x, y, w, rows, wx, xs, ys);
            }
            r[k] = std::isfinite(result) ? result : NA_REAL;
        }
    }
    writable::list out({r, n});
    out.names() = {"r", "n"};
    return out;
}

// Spearman correlations, sample sizes and p-values for every pair, in
// combn() order, matching pwcorr_pair(): cor(method = "spearman") on each
// pair's complete rows and spearman_p() on their ranks. Ranks and power sums
// of fully observed columns are computed once.
[[cpp11::register]] writable::list pwcorr_spearman(list columns)
{
    const R_xlen_t nrow = pwcorr_rows(columns);
    const R_xlen_t p = columns.size();
    std::vector<numeric_view> values;
    values.reserve(p);
    std::vector<char> complete(p, 1);
    for (R_xlen_t j = 0; j < p; ++j) {
        values.emplace_back(VECTOR_ELT(columns, j));
        for (R_xlen_t row = 0; row < nrow && complete[j]; ++row) {
            if (ISNAN(values[j][row])) complete[j] = 0;
        }
    }
    const R_xlen_t pairs = p * (p - 1) / 2;
    writable::doubles r(pairs), n(pairs), pv(pairs);
    std::vector<spearman_column> cache(p);
    std::vector<R_xlen_t> rows, order, identity;
    std::vector<double> sub_x, sub_y, rank_x, rank_y, center_x, center_y;
    spearman_scratch scratch;
    auto prepare = [&](R_xlen_t j) -> spearman_column& {
        spearman_column& column = cache[j];
        if (!column.ready) {
            sub_x.resize(nrow);
            for (R_xlen_t row = 0; row < nrow; ++row) sub_x[row] = values[j][row];
            pwcorr_rank(sub_x, column.ranks, order);
            spearman_center(column.ranks, column.centered, scratch);
            column.ready = true;
        }
        return column;
    };
    auto summed = [&](spearman_column& column) -> const spearman_sums& {
        if (!column.summed) {
            column.sums = spearman_power_sums(column.centered, scratch);
            column.summed = true;
        }
        return column.sums;
    };
    R_xlen_t k = 0;
    for (R_xlen_t i = 0; i < p; ++i) {
        for (R_xlen_t j = i + 1; j < p; ++j, ++k) {
            check_user_interrupt();
            const numeric_view& x = values[i];
            const numeric_view& y = values[j];
            const bool full = complete[i] && complete[j];
            rows.clear();
            if (!full) {
                for (R_xlen_t row = 0; row < nrow; ++row) {
                    if (!ISNAN(x[row]) && !ISNAN(y[row])) rows.push_back(row);
                }
            }
            const R_xlen_t m = full ? nrow : rows.size();
            n[k] = m;
            if (m <= 1) {
                r[k] = NA_REAL;
                pv[k] = NA_REAL;
                continue;
            }
            const std::vector<double>* rx;
            const std::vector<double>* ry;
            spearman_column* cx = nullptr;
            spearman_column* cy = nullptr;
            if (full) {
                cx = &prepare(i);
                cy = &prepare(j);
                rx = &cx->ranks;
                ry = &cy->ranks;
            } else {
                sub_x.resize(m);
                sub_y.resize(m);
                for (R_xlen_t t = 0; t < m; ++t) {
                    sub_x[t] = x[rows[t]];
                    sub_y[t] = y[rows[t]];
                }
                pwcorr_rank(sub_x, rank_x, order);
                pwcorr_rank(sub_y, rank_y, order);
                rx = &rank_x;
                ry = &rank_y;
            }
            identity.resize(m);
            std::iota(identity.begin(), identity.end(), 0);
            double rho = pwcorr_complete(*rx, *ry, identity);
            if (!std::isfinite(rho)) rho = NA_REAL;
            r[k] = rho;
            if (ISNAN(rho) || m < 3) {
                pv[k] = NA_REAL;
                continue;
            }
            if (full) {
                const spearman_sums& sx = summed(*cx);
                const spearman_sums& sy = summed(*cy);
                pv[k] = spearman_p(cx->centered, cy->centered, sx, sy, rho);
            } else {
                spearman_center(rank_x, center_x, scratch);
                spearman_center(rank_y, center_y, scratch);
                spearman_sums sx{}, sy{};
                if (m >= 4) {
                    sx = spearman_power_sums(center_x, scratch);
                    sy = spearman_power_sums(center_y, scratch);
                }
                pv[k] = spearman_p(center_x, center_y, sx, sy, rho);
            }
        }
    }
    writable::list out({r, n, pv});
    out.names() = {"r", "n", "p"};
    return out;
}
