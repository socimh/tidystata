#include "cpp11.hpp"
#include "cpp11/doubles.hpp"
#include "cpp11/integers.hpp"
#include "cpp11/list.hpp"
#include "numeric_view.h"
#include "r_math.h"
#include <Rmath.h>
#include <algorithm>
#include <cfloat>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <string>
#include <unordered_map>
#include <vector>

using namespace cpp11;
namespace writable = cpp11::writable;

namespace {

double summary_sum(long double x)
{
    return x > DBL_MAX ? R_PosInf : x < -DBL_MAX ? R_NegInf : static_cast<double>(x);
}

// A total order, including deviations such as Inf - Inf. Equal values keep
// their input order, including signed zero and weighted percentile ties.
bool summary_less(double a, double b)
{
    if (ISNAN(a)) return false;
    if (ISNAN(b)) return true;
    return a < b;
}

double summary_mean(const std::vector<double>& x)
{
    long double total = 0;
    for (double value : x) total += value;
    if (R_FINITE(static_cast<double>(total))) {
        total /= x.size();
    } else {
        total = 0;
        for (double value : x) total += value / x.size();
    }
    if (R_FINITE(static_cast<double>(total))) {
        long double residual = 0;
        for (double value : x) residual += value - total;
        total += residual / x.size();
    }
    return static_cast<double>(total);
}

double summary_sd(const std::vector<double>& x)
{
    if (x.size() <= 1) return NA_REAL;
    long double total = 0;
    for (double value : x) {
        if (ISNAN(value)) return NA_REAL;
        total += value;
    }
    long double center = total / x.size();
    if (R_FINITE(static_cast<double>(center))) {
        total = 0;
        for (double value : x) total += value - center;
        center += total / x.size();
    }
    const long double rounded = static_cast<double>(center);
    total = 0;
    for (double value : x) {
        const long double deviation = value - rounded;
        total += deviation * deviation;
    }
    return r_sqrt(static_cast<double>(total / (x.size() - 1)));
}

double summary_midpoint(double a, double b)
{
    const double midpoint = (a + b) / 2;
    return std::isinf(midpoint) && std::isfinite(a) && std::isfinite(b) ?
        a / 2 + b / 2 : midpoint;
}

double summary_median(const std::vector<double>& sorted)
{
    if (sorted.empty() || ISNAN(sorted.back())) return NA_REAL;
    const size_t mid = sorted.size() / 2;
    if (sorted.size() % 2) return sorted[mid];
    // median() uses mean() for its two middle observations.
    return summary_mean(std::vector<double>{sorted[mid - 1], sorted[mid]});
}

uint64_t summary_sort_key(double value)
{
    if (ISNAN(value)) return UINT64_MAX;
    uint64_t bits;
    // R's stable numeric ordering treats signed zeros and missing payloads as
    // ties. Preserve the original doubles while sorting by normalized keys.
    if (value == 0) value = 0;
    std::memcpy(&bits, &value, sizeof(bits));
    const uint64_t sign = UINT64_C(1) << 63;
    return bits & sign ? ~bits : bits ^ sign;
}

void summary_sort(std::vector<double>& values, std::vector<double>& scratch)
{
    if (values.size() <= 2048) {
        std::stable_sort(values.begin(), values.end(), summary_less);
        return;
    }
    scratch.resize(values.size());
    for (unsigned shift = 0; shift < 64; shift += 8) {
        size_t offsets[256] = {};
        for (double value : values) ++offsets[(summary_sort_key(value) >> shift) & 255];
        size_t start = 0;
        for (size_t& offset : offsets) {
            const size_t size = offset;
            offset = start;
            start += size;
        }
        for (double value : values) {
            scratch[offsets[(summary_sort_key(value) >> shift) & 255]++] = value;
        }
        values.swap(scratch);
    }
}

const int* summary_rows(SEXP loc, R_xlen_t size)
{
    if (TYPEOF(loc) != INTSXP) stop("Group locations must be integer vectors.");
    const int* rows = INTEGER_RO(loc);
    for (R_xlen_t i = 0; i < Rf_xlength(loc); ++i) {
        if (rows[i] == NA_INTEGER || rows[i] < 1 || rows[i] > size) {
            stop("Group locations must index the input.");
        }
    }
    return rows;
}

struct summary_request {
    std::vector<std::string> names;
    bool mean = false, spread = false, sorted = false, mad = false;
    bool sum = false, minimum = false, maximum = false, median = false, iqr = false;
    summary_request(strings statistics, doubles probs, integers index)
    {
        if (statistics.size() != index.size()) stop("Statistic indices must match.");
        for (R_xlen_t j = 0; j < statistics.size(); ++j) {
            const std::string name = static_cast<std::string>(statistics[j]);
            names.push_back(name);
            if (index[j] == NA_INTEGER || index[j] < 0 || index[j] > probs.size()) {
                stop("Invalid percentile index.");
            }
            mean |= name == "mean" || name == "skew" || name == "kurtosis";
            spread |= name == "sd" || name == "se" || name == "skew" || name == "kurtosis";
            sorted |= index[j] > 0 || name == "median" || name == "mad" || name == "iqr";
            mad |= name == "mad";
            median |= name == "median" || name == "mad";
            iqr |= name == "iqr";
            sum |= name == "sum";
            minimum |= name == "min";
            maximum |= name == "max";
        }
        for (double p : probs) {
            if (!std::isfinite(p) || p < 0 || p > 1) stop("Invalid percentile probability.");
        }
    }
};

double summary_quantile(const std::vector<double>& sorted, double p, bool grouped)
{
    if (sorted.empty()) return NA_REAL;
    if (p <= 0) return sorted.front();
    if (p >= 1) return sorted.back();
    const double target = sorted.size() * p;
    const double tolerance = r_sqrt(DBL_EPSILON) * sorted.size();
    if (grouped) {
        const double whole = std::nearbyint(target);
        const bool exact = std::fabs(target - whole) <= tolerance &&
            whole >= 1 && whole < sorted.size();
        const size_t position = static_cast<size_t>(exact ? whole - 1 : std::floor(target));
        return exact ? summary_midpoint(sorted[position], sorted[position + 1]) : sorted[position];
    }
    // Match the first cumulative weight within tolerance, as weighted_quantile().
    const double first = std::max(1.0, std::ceil(target - tolerance));
    if (first < sorted.size() && std::fabs(first - target) <= tolerance) {
        return summary_midpoint(sorted[static_cast<size_t>(first) - 1],
                                sorted[static_cast<size_t>(first)]);
    }
    const size_t above = static_cast<size_t>(std::floor(target));
    if (above >= sorted.size()) stop("subscript out of bounds");
    return sorted[above];
}

} // namespace

// Only observed row locations enter these kernels. R retains raw metadata,
// nonnumeric counts and restoration; scratch is reused between groups.
[[cpp11::register]] writable::list group_summary_dbl(
    SEXP x, list locs, strings statistics, doubles probs, integers quantile_index, bool grouped)
{
    summary_request request(statistics, probs, quantile_index);
    writable::list out(statistics.size());
    for (R_xlen_t j = 0; j < statistics.size(); ++j) {
        out[j] = writable::doubles(locs.size());
    }
    // Logical and integer input is read in place rather than copied by R.
    const numeric_view values(x);
    const R_xlen_t size = Rf_xlength(x);
    std::vector<double> observed, sorted, deviation, scratch;
    for (R_xlen_t g = 0; g < locs.size(); ++g) {
        if (g % 256 == 0) check_user_interrupt();
        SEXP loc = VECTOR_ELT(locs, g);
        const int* rows = summary_rows(loc, size);
        const R_xlen_t n = Rf_xlength(loc);
        observed.resize(n);
        for (R_xlen_t i = 0; i < n; ++i) observed[i] = values[rows[i] - 1];
        const double center = n && request.mean ? summary_mean(observed) : NA_REAL;
        const double spread = n && request.spread ? summary_sd(observed) : NA_REAL;
        double population = spread * r_sqrt((static_cast<double>(n) - 1) / n);
        if (population == 0) population = NA_REAL;
        double minimum = R_PosInf, maximum = R_NegInf;
        long double total = 0;
        if (request.sum || request.minimum || request.maximum) {
            for (double value : observed) {
                if (request.sum) total += value;
                if (request.minimum && (value < minimum || ISNAN(value))) minimum = value;
                if (request.maximum && (value > maximum || ISNAN(value))) maximum = value;
            }
        }
        double median = NA_REAL, mad = NA_REAL;
        if (n && request.sorted) {
            sorted.assign(observed.begin(), observed.end());
            summary_sort(sorted, scratch);
            if (request.median) median = summary_median(sorted);
            if (request.mad) {
                deviation.resize(n);
                for (R_xlen_t i = 0; i < n; ++i) deviation[i] = std::fabs(observed[i] - median);
                summary_sort(deviation, scratch);
                mad = 1.4826 * summary_median(deviation);
            }
        }
        for (R_xlen_t j = 0; j < statistics.size(); ++j) {
            double result = NA_REAL;
            const std::string& name = request.names[j];
            if (n) {
                if (quantile_index[j]) result = summary_quantile(sorted, probs[quantile_index[j] - 1], grouped);
                else if (name == "mean") result = center;
                else if (name == "sd") result = spread;
                else if (name == "se") result = spread / r_sqrt(static_cast<double>(n));
                else if (name == "min") result = minimum;
                else if (name == "max") result = maximum;
                else if (name == "sum") result = summary_sum(total);
                else if (name == "median") result = median;
                else if (name == "mad") result = mad;
                else if (name == "iqr") result = summary_quantile(sorted, .75, grouped) - summary_quantile(sorted, .25, grouped);
                else if (name == "skew" || name == "kurtosis") {
                    const double power = name == "skew" ? 3 : 4;
                    long double moment = 0;
                    for (double value : observed) {
                        const double term = R_pow(value - center, power);
                        moment += term;
                    }
                    result = summary_sum(moment) / (n * R_pow(population, power));
                }
            }
            REAL(VECTOR_ELT(out, j))[g] = result;
        }
    }
    return out;
}

[[cpp11::register]] writable::integers group_unique_id(integers ids, list locs)
{
    int largest = 0;
    for (int id : ids) {
        if (id == NA_INTEGER || id < 1 || id > ids.size()) stop("Invalid category identity.");
        largest = std::max(largest, id);
    }
    // One stamp per raw identity avoids both a row/group data frame and a
    // separately allocated hash node for each observation in every group.
    std::vector<R_xlen_t> seen(static_cast<size_t>(largest) + 1, -1);
    writable::integers out(locs.size());
    const int* identity = INTEGER_RO(ids);
    for (R_xlen_t g = 0; g < locs.size(); ++g) {
        if (g % 256 == 0) check_user_interrupt();
        SEXP loc = VECTOR_ELT(locs, g);
        const int* rows = summary_rows(loc, ids.size());
        int count = 0;
        for (R_xlen_t i = 0; i < Rf_xlength(loc); ++i) {
            const int id = identity[rows[i] - 1];
            if (seen[id] != g) { seen[id] = g; ++count; }
        }
        out[g] = count;
    }
    return out;
}

namespace {

struct summary_weighted_value {
    double value, raw, weight, probability;
    R_xlen_t order;
};

// entries remain in row order until every reduction is finished. Products,
// residuals and powers round to double before the extended-precision sum.
double summary_weighted_average(const std::vector<summary_weighted_value>& entries,
                                double raw_total, double center, double power)
{
    auto value_of = [=](const summary_weighted_value& entry) {
        if (power == 0) return entry.value;
        return entry.weight == 0 ? 0.0 : R_pow(entry.value - center, power);
    };
    long double total = 0;
    for (const auto& entry : entries) {
        const double term = entry.weight == 0 ? 0.0 : entry.raw * value_of(entry);
        total += term;
    }
    const double numerator = summary_sum(total);
    if (std::isfinite(numerator) && std::isfinite(raw_total) && numerator != 0) {
        return numerator / raw_total;
    }
    total = 0;
    for (const auto& entry : entries) {
        const double value = value_of(entry);
        const double term = entry.weight == 0 ? 0.0 :
            std::isinf(value) ? value : entry.probability * value;
        total += term;
    }
    return summary_sum(total);
}

void summary_weighted_sort(std::vector<summary_weighted_value>& entries,
                           std::vector<double>& cumulative, bool original_ties = false)
{
    std::stable_sort(entries.begin(), entries.end(), [=](const summary_weighted_value& a, const summary_weighted_value& b) {
        if (summary_less(a.value, b.value)) return true;
        if (summary_less(b.value, a.value)) return false;
        return original_ties && a.order < b.order;
    });
    cumulative.resize(entries.size());
    long double total = 0;
    double maximum = 0;
    for (size_t i = 0; i < entries.size(); ++i) {
        total += entries[i].weight;
        maximum = std::max(maximum, entries[i].weight);
        cumulative[i] = summary_sum(total);
    }
    if (total > DBL_MAX) {
        total = 0;
        for (size_t i = 0; i < entries.size(); ++i) {
            const double term = entries[i].weight / maximum;
            total += term;
            cumulative[i] = summary_sum(total);
        }
    }
}

double summary_weighted_quantile(const std::vector<summary_weighted_value>& sorted,
                                 const std::vector<double>& cumulative, double p)
{
    if (sorted.empty()) return NA_REAL;
    if (p <= 0) return sorted.front().value;
    if (p >= 1) return sorted.back().value;
    const double total = cumulative.back();
    const double target = p * total;
    const double tolerance = r_sqrt(DBL_EPSILON) * total;
    for (size_t i = 0; i < sorted.size(); ++i) {
        if (std::fabs(cumulative[i] - target) <= tolerance) {
            if (i + 1 < sorted.size()) {
                return summary_midpoint(sorted[i].value, sorted[i + 1].value);
            }
            break;
        }
    }
    for (size_t i = 0; i < sorted.size(); ++i) {
        if (cumulative[i] > target) return sorted[i].value;
    }
    stop("subscript out of bounds");
}

} // namespace

[[cpp11::register]] writable::list group_weighted_summary_dbl(
    SEXP x, doubles weights, list locs, bool analytic, bool grouped,
    strings statistics, doubles probs, integers quantile_index)
{
    const bool has_values = x != R_NilValue;
    if (has_values && Rf_xlength(x) != weights.size()) {
        stop("Numeric values must match weights.");
    }
    // Without values, read the weights so the view is always valid.
    const numeric_view values(has_values ? x : static_cast<SEXP>(weights));
    const double* raw_weights = REAL_RO(weights);
    summary_request request(statistics, probs, quantile_index);
    writable::list out(statistics.size());
    for (R_xlen_t j = 0; j < statistics.size(); ++j) {
        out[j] = writable::doubles(locs.size());
    }
    std::vector<summary_weighted_value> entries;
    std::vector<double> cumulative, quantiles(probs.size());
    for (R_xlen_t g = 0; g < locs.size(); ++g) {
        if (g % 256 == 0) check_user_interrupt();
        SEXP loc = VECTOR_ELT(locs, g);
        const int* rows = summary_rows(loc, weights.size());
        const R_xlen_t n = Rf_xlength(loc);
        double maximum_weight = 0;
        for (R_xlen_t i = 0; i < n; ++i) {
            const double w = raw_weights[rows[i] - 1];
            if (!std::isfinite(w) || w < 0) stop("Weights must be finite and nonnegative.");
            maximum_weight = std::max(maximum_weight, w);
        }
        if (maximum_weight == 0) maximum_weight = 1;
        long double mass_sum = 0;
        for (R_xlen_t i = 0; i < n; ++i) {
            const double normalized = raw_weights[rows[i] - 1] / maximum_weight;
            mass_sum += normalized;
        }
        const double mass = summary_sum(mass_sum);
        entries.clear();
        long double weight_sum = 0, raw_sum = 0, value_sum = 0;
        double minimum = R_PosInf, maximum = R_NegInf;
        for (R_xlen_t i = 0; i < n; ++i) {
            const R_xlen_t row = rows[i] - 1;
            const double raw = raw_weights[row];
            const double normalized = raw / maximum_weight;
            const double w = analytic && mass > 0 ? normalized * (n / mass) : raw;
            weight_sum += w;
            // Keep the established many-small-groups arithmetic: its raw sum
            // includes positive raw weights whose analytic scaling underflows.
            if (!grouped && !(w > 0)) continue;
            const double probability = grouped && mass == 0 ? 0.0 : normalized / mass;
            const double value = has_values ? values[row] : NA_REAL;
            entries.push_back({value, raw, w, probability, i});
            raw_sum += raw;
            if (request.sum && has_values) {
                const double product = raw == 0 ? 0.0 : raw * value;
                value_sum += product;
            }
            if (w > 0 && has_values) {
                if (value < minimum || ISNAN(value)) minimum = value;
                if (value > maximum || ISNAN(value)) maximum = value;
            }
        }
        const double total = summary_sum(weight_sum);
        const double raw_total = summary_sum(raw_sum);
        const bool has = has_values && n > 0 && total > 0;
        const double center = has && (request.mean || request.spread) ?
            summary_weighted_average(entries, raw_total, 0, 0) : NA_REAL;
        double population = NA_REAL, spread = NA_REAL;
        if (has && request.spread) {
            population = std::isfinite(minimum) && minimum == maximum ? 0.0 :
                r_sqrt(summary_weighted_average(entries, raw_total, center, 2));
            if (total > 1) {
                const double correction = std::isinf(total) ? 1.0 : (total - 1) / total;
                spread = population / r_sqrt(correction);
            } else if (grouped) {
                // The grouped R path divides by an NA correction for totals
                // <= 1, retaining a NaN population. The single/few path
                // explicitly returns NA instead. Preserve both results.
                spread = population / r_sqrt(NA_REAL);
            }
            if (population == 0) population = NA_REAL;
        }
        double skew = NA_REAL, kurtosis = NA_REAL;
        if (has) {
            for (const auto& name : request.names) {
                if (name == "skew") skew = summary_weighted_average(entries, raw_total, center, 3) / R_pow(population, 3);
                if (name == "kurtosis") kurtosis = summary_weighted_average(entries, raw_total, center, 4) / R_pow(population, 4);
            }
        }
        double median = NA_REAL, mad = NA_REAL, iqr = NA_REAL;
        if (has && request.sorted) {
            entries.erase(std::remove_if(entries.begin(), entries.end(), [](const summary_weighted_value& entry) {
                return !(entry.weight > 0);
            }), entries.end());
            summary_weighted_sort(entries, cumulative);
            for (R_xlen_t j = 0; j < probs.size(); ++j) {
                quantiles[j] = summary_weighted_quantile(entries, cumulative, probs[j]);
            }
            if (request.median) median = summary_weighted_quantile(entries, cumulative, .5);
            if (request.iqr) iqr = summary_weighted_quantile(entries, cumulative, .75) -
                summary_weighted_quantile(entries, cumulative, .25);
            if (request.mad) {
                for (auto& entry : entries) entry.value = std::fabs(entry.value - median);
                summary_weighted_sort(entries, cumulative, true);
                mad = 1.4826 * summary_weighted_quantile(entries, cumulative, .5);
            }
        }
        for (R_xlen_t j = 0; j < statistics.size(); ++j) {
            const std::string& name = request.names[j];
            double result = NA_REAL;
            if (name == "n") result = total;
            else if (has) {
                if (quantile_index[j]) result = quantiles[quantile_index[j] - 1];
                else if (name == "mean") result = center;
                else if (name == "sd") result = spread;
                else if (name == "se") result = spread / r_sqrt(total);
                else if (name == "min") result = minimum;
                else if (name == "max") result = maximum;
                else if (name == "sum") result = summary_sum(value_sum);
                else if (name == "median") result = median;
                else if (name == "mad") result = mad;
                else if (name == "iqr") result = iqr;
                else if (name == "skew") result = skew;
                else if (name == "kurtosis") result = kurtosis;
            }
            REAL(VECTOR_ELT(out, j))[g] = result;
        }
    }
    return out;
}

// Dense integer/factor keys can be indexed without allocating full-length
// identity codes or row locations. NULL means the range is too sparse.
[[cpp11::register]] SEXP tab_integer_range(SEXP x)
{
    if (TYPEOF(x) != INTSXP && TYPEOF(x) != LGLSXP) stop("Integer categories required.");
    const R_xlen_t size = Rf_xlength(x);
    if (!size || size > INT_MAX) return R_NilValue;
    const int* values = TYPEOF(x) == LGLSXP ? LOGICAL_RO(x) : INTEGER_RO(x);
    int minimum = INT_MAX, maximum = INT_MIN;
    bool missing = false;
    for (R_xlen_t i = 0; i < size; ++i) {
        const int value = values[i];
        if (value == NA_INTEGER) missing = true;
        else { minimum = std::min(minimum, value); maximum = std::max(maximum, value); }
    }
    if (maximum == INT_MIN) { minimum = 0; maximum = -1; }
    const int64_t span = static_cast<int64_t>(maximum) - minimum + 1;
    if (span + missing > size) return R_NilValue;
    return writable::integers({minimum, static_cast<int>(span), static_cast<int>(missing)});
}

// Bounded character dictionaries avoid an input-sized vctrs hash/sort arena.
// Normalize distinct CHARSXPs once; retain raw first rows for R's key sorting.
[[cpp11::register]] SEXP tab_character_id(strings x, int maximum)
{
    if (maximum < 1) return R_NilValue;
    maximum = std::min(maximum, 4096);
    writable::integers ids(x.size());
    std::unordered_map<SEXP, int> pointers;
    std::unordered_map<std::string, int> identities;
    std::vector<sexp> protected_strings;
    std::vector<int> first;
    int missing = 0;
    for (R_xlen_t i = 0; i < x.size(); ++i) {
        if (i % 65536 == 0) check_user_interrupt();
        SEXP value = STRING_ELT(x, i);
        auto cached = pointers.find(value);
        if (cached != pointers.end()) { ids[i] = cached->second; continue; }
        // ALTREP character vectors need not retain a materialized CHARSXP.
        protected_strings.emplace_back(value);
        int id = 0;
        if (value == NA_STRING) id = missing;
        else {
            if (Rf_getCharCE(value) == CE_BYTES) return R_NilValue;
            const std::string key = safe[Rf_translateCharUTF8](value);
            auto found = identities.find(key);
            if (found != identities.end()) id = found->second;
            else {
                if (first.size() >= static_cast<size_t>(maximum)) return R_NilValue;
                id = static_cast<int>(first.size()) + 1;
                first.push_back(static_cast<int>(i + 1));
                identities.emplace(key, id);
            }
        }
        if (value == NA_STRING && !id) {
            if (first.size() >= static_cast<size_t>(maximum)) return R_NilValue;
            id = static_cast<int>(first.size()) + 1;
            first.push_back(static_cast<int>(i + 1));
            missing = id;
        }
        pointers.emplace(value, id);
        ids[i] = id;
    }
    writable::integers locations(first.size());
    std::copy(first.begin(), first.end(), INTEGER(locations));
    writable::list out(2);
    out[0] = ids;
    out[1] = locations;
    return out;
}

// Both dimensions have dense integer identities. A character dimension supplies
// appearance codes plus R/vctrs's order of its compact dictionary. Other integer
// dimensions use their raw values and range, including a final missing cell.
[[cpp11::register]] SEXP tab_count_dense(
    SEXP x, integers range, SEXP other, integers other_range, integers order,
    SEXP weights, bool integer_first)
{
    if (TYPEOF(x) != INTSXP && TYPEOF(x) != LGLSXP) stop("Integer categories required.");
    if (TYPEOF(other) != INTSXP && TYPEOF(other) != LGLSXP) stop("Integer categories required.");
    const R_xlen_t size = Rf_xlength(x);
    if (Rf_xlength(other) != size) stop("Category identities must have equal lengths.");
    if (range.size() != 3 || range[1] < 0 || range[2] < 0 || range[2] > 1 ||
        (other_range.size() && (other_range.size() != 3 || other_range[1] < 0 ||
                               other_range[2] < 0 || other_range[2] > 1))) {
        stop("Invalid integer category range.");
    }
    if (weights != R_NilValue && (TYPEOF(weights) != REALSXP || Rf_xlength(weights) != size)) {
        stop("Weights must match category identities.");
    }
    const uint64_t dimension = static_cast<uint64_t>(range[1]) + range[2];
    const uint64_t other_dimension = other_range.size() ?
        static_cast<uint64_t>(other_range[1]) + other_range[2] : order.size();
    const uint64_t grid = dimension * other_dimension;
    if (size > INT_MAX || grid > static_cast<uint64_t>(size)) return R_NilValue;
    for (int rank : order) {
        if (rank == NA_INTEGER || rank < 0 || static_cast<uint64_t>(rank) >= other_dimension) {
            stop("Invalid category order.");
        }
    }
    const size_t cells = static_cast<size_t>(grid);
    const int* values = TYPEOF(x) == LGLSXP ? LOGICAL_RO(x) : INTEGER_RO(x);
    const int* others = TYPEOF(other) == LGLSXP ? LOGICAL_RO(other) : INTEGER_RO(other);
    const double* w = weights == R_NilValue ? nullptr : REAL_RO(weights);
    std::vector<int> first(cells, 0), counts(w ? 0 : cells, 0);
    std::vector<long double> sums(w ? cells : 0, 0);
    R_xlen_t observed = 0;
    for (R_xlen_t i = 0; i < size; ++i) {
        if (i % 65536 == 0) check_user_interrupt();
        const int value = values[i], other_value = others[i];
        const int64_t id = value == NA_INTEGER ? range[1] : static_cast<int64_t>(value) - range[0];
        int64_t other_id;
        if (other_range.size()) {
            other_id = other_value == NA_INTEGER ? other_range[1] :
                static_cast<int64_t>(other_value) - other_range[0];
        } else {
            if (other_value < 1 || static_cast<uint64_t>(other_value) > other_dimension) {
                stop("Invalid category identity.");
            }
            other_id = order[other_value - 1];
        }
        if (id < 0 || static_cast<uint64_t>(id) >= dimension || other_id < 0 ||
            static_cast<uint64_t>(other_id) >= other_dimension) stop("Invalid category identity.");
        const size_t cell = integer_first ? static_cast<size_t>(id) * other_dimension + other_id :
            static_cast<size_t>(other_id) * dimension + id;
        if (first[cell] == 0) { first[cell] = static_cast<int>(i + 1); ++observed; }
        if (w) sums[cell] += w[i];
        else ++counts[cell];
    }
    writable::integers locations(observed);
    writable::list out(2);
    out[1] = w ? static_cast<SEXP>(writable::doubles(observed)) :
        static_cast<SEXP>(writable::integers(observed));
    R_xlen_t k = 0;
    for (size_t cell = 0; cell < cells; ++cell) {
        if (!first[cell]) continue;
        locations[k] = first[cell];
        if (w) REAL(VECTOR_ELT(out, 1))[k] = summary_sum(sums[cell]);
        else INTEGER(VECTOR_ELT(out, 1))[k] = counts[cell];
        ++k;
    }
    out[0] = locations;
    return out;
}

// Sums and cumulative sums over the 1-based row locations of each group.
// Both accumulate in long double in location order, as base sum() and
// cumsum() do, without allocating one subset per group. As in base R,
// arithmetic mixing NA and NaN does not guarantee which missing payload wins.

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
    const double epsilon = r_sqrt(DBL_EPSILON);
    R_xlen_t start = 0;
    for (R_xlen_t g = 0; g < groups; ++g) {
        kept.clear();
        cumulative.clear();
        long double running = 0.0L;
        double maximum = 0.0;
        for (R_xlen_t k = start; k < start + n[g]; ++k) {
            if (!(w[k] > 0)) continue;
            kept.push_back(x[k]);
            maximum = std::max(maximum, w[k]);
            running += w[k];
            cumulative.push_back(static_cast<double>(running));
        }
        // Only overflowing totals need a second pass with scaled weights.
        if (running > DBL_MAX) {
            cumulative.clear();
            running = 0.0L;
            for (R_xlen_t k = start; k < start + n[g]; ++k) {
                if (!(w[k] > 0)) continue;
                running += w[k] / maximum;
                cumulative.push_back(static_cast<double>(running));
            }
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
                double a = kept[exact];
                double b = kept[exact + 1];
                double midpoint = (a + b) / 2;
                q = std::isinf(midpoint) && std::isfinite(a) && std::isfinite(b) ?
                    a / 2 + b / 2 : midpoint;
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
