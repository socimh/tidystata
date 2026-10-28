#include "cpp11.hpp"
#include "cpp11/doubles.hpp"
#include "cpp11/integers.hpp"
#include "cpp11/list.hpp"
#include <unordered_set>
#include <utility>
#include <vector>

using namespace cpp11;
namespace writable = cpp11::writable;

namespace {

// Cache read-only pointers, retaining the original missing payload. SPSS
// normalization belongs to the reader so neither x nor a default needs a copy.
class recode_source {
    const double* real_ = nullptr;
    const int* integer_ = nullptr;
    std::vector<double> na_values_;
    bool has_range_ = false;
    double lower_ = 0;
    double upper_ = 0;

public:
    explicit recode_source(SEXP x)
    {
        switch (TYPEOF(x)) {
        case REALSXP: real_ = REAL_RO(x); break;
        case INTSXP: integer_ = INTEGER_RO(x); break;
        case LGLSXP: integer_ = LOGICAL_RO(x); break;
        default: stop("Recode data must be integer or double vectors.");
        }
        if (!Rf_inherits(x, "haven_labelled_spss")) return;
        SEXP values = Rf_getAttrib(x, Rf_install("na_values"));
        if (values != R_NilValue) {
            recode_source codes(values);
            for (R_xlen_t j = 0; j < Rf_xlength(values); ++j) {
                na_values_.push_back(codes[j]);
            }
        }
        SEXP range = Rf_getAttrib(x, Rf_install("na_range"));
        if (range != R_NilValue && Rf_xlength(range) == 2) {
            recode_source bounds(range);
            has_range_ = true;
            lower_ = bounds[0];
            upper_ = bounds[1];
        }
    }

    double operator[](R_xlen_t i) const
    {
        // Every non-missing R integer is exactly representable as a double;
        // this comparison value does not determine the result's storage type.
        double value = real_ ? real_[i] :
            (integer_[i] == NA_INTEGER ? NA_REAL : static_cast<double>(integer_[i]));
        if (ISNAN(value)) return value;
        if (has_range_ && value >= lower_ && value <= upper_) return NA_REAL;
        for (double code : na_values_) {
            if (value == code) return NA_REAL;
        }
        return value;
    }
};

class recode_matcher {
    bool missing_;
    bool singleton_;
    double value_ = 0;
    std::unordered_set<double> values_;
    std::vector<std::pair<double, double>> intervals_;

public:
    double code;

    explicit recode_matcher(list rule)
    {
        list selector = rule["select"];
        doubles values = selector["values"];
        doubles lower = selector["lower"];
        doubles upper = selector["upper"];
        missing_ = as_cpp<bool>(selector["missing"]);
        singleton_ = values.size() == 1;
        if (singleton_) {
            value_ = values[0];
        } else if (values.size() > 1) {
            values_.reserve(values.size());
            for (double value : values) values_.insert(value);
        }
        for (R_xlen_t j = 0; j < lower.size(); ++j) {
            intervals_.emplace_back(lower[j], upper[j]);
        }
        recode_source replacement(rule["code"]);
        code = replacement[0];
    }

    bool matches(double value) const
    {
        if (ISNAN(value)) return missing_;
        if (singleton_ && value == value_) return true;
        if (!values_.empty() && values_.find(value) != values_.end()) return true;
        for (const auto& interval : intervals_) {
            if (value >= interval.first && value <= interval.second) return true;
        }
        return false;
    }
};

// Only integer output maps every missing payload to NA_INTEGER.
template <typename T> T recode_cast(double value);
template <> double recode_cast<double>(double value) { return value; }
template <> int recode_cast<int>(double value)
{
    return ISNAN(value) ? NA_INTEGER : static_cast<int>(value);
}

template <typename T>
SEXP recode_fill(SEXP x, const std::vector<recode_matcher>& rules, SEXP fallback)
{
    recode_source input(x);
    // NULL means keep the normalized input; otherwise read a scalar or vector.
    bool keep = fallback == R_NilValue;
    recode_source defaults(keep ? x : fallback);
    bool scalar = !keep && Rf_xlength(fallback) == 1;
    R_xlen_t n = Rf_xlength(x);
    writable::r_vector<T> out(n);
    for (R_xlen_t i = 0; i < n; ++i) {
        if (i % 65536 == 0) check_user_interrupt();
        double original = input[i];
        double result = 0;
        bool matched = false;
        for (const auto& rule : rules) {
            if (rule.matches(original)) {
                result = rule.code;
                matched = true;
                break;
            }
        }
        if (!matched) result = keep ? original : defaults[scalar ? 0 : i];
        // Integer output is selected only after R has established a common type.
        out[i] = recode_cast<T>(result);
    }
    return out;
}

} // namespace

[[cpp11::register]] SEXP recode_apply(SEXP x, list rules, SEXP fallback, SEXP ptype)
{
    std::vector<recode_matcher> prepared;
    prepared.reserve(rules.size());
    for (R_xlen_t j = 0; j < rules.size(); ++j) {
        prepared.emplace_back(static_cast<SEXP>(rules[j]));
    }
    // R selects storage before matching; never infer it from observed values.
    if (TYPEOF(ptype) == INTSXP) {
        return recode_fill<int>(x, prepared, fallback);
    }
    return recode_fill<double>(x, prepared, fallback);
}
