#include "cpp11.hpp"
#include "cpp11/doubles.hpp"
#include "cpp11/integers.hpp"
#include <algorithm>
#include <utility>
#include <vector>

using namespace cpp11;
namespace writable = cpp11::writable;

// For each row, the 1-based row whose period equals period - shift, or NA,
// as match(period - shift, period) gives for distinct periods. Rows are
// visited in ascending period order, so one forward walk finds every target:
// subtracting a constant keeps the targets in order. `order` supplies that
// order for long vectors (R's radix sort is faster there); otherwise unsorted
// periods are sorted here, avoiding order()'s per-call cost in small groups.
// Periods must not be missing. Returns NULL if two periods are equal, so the
// caller can report the repeated time.
[[cpp11::register]] SEXP panel_lag_index(doubles period, SEXP order, double shift)
{
    const double* value = REAL_RO(period);
    R_xlen_t n = period.size();
    std::vector<int> sorted;
    if (order != R_NilValue) {
        if (TYPEOF(order) != INTSXP || Rf_xlength(order) != n) {
            stop("`order` must be an integer permutation of the periods.");
        }
        const int* given = INTEGER_RO(order);
        sorted.assign(given, given + n);
        for (int& row : sorted) --row;
    } else if (!std::is_sorted(value, value + n)) {
        std::vector<std::pair<double, int>> pairs(n);
        for (R_xlen_t i = 0; i < n; ++i) pairs[i] = {value[i], static_cast<int>(i)};
        std::sort(pairs.begin(), pairs.end());
        sorted.resize(n);
        for (R_xlen_t k = 0; k < n; ++k) sorted[k] = pairs[k].second;
    }
    auto row = [&](R_xlen_t k) -> R_xlen_t { return sorted.empty() ? k : sorted[k]; };
    for (R_xlen_t k = 1; k < n; ++k) {
        if (!(value[row(k)] > value[row(k - 1)])) return R_NilValue;
    }
    writable::integers out(n);
    int* result = INTEGER(out);
    R_xlen_t j = 0;
    for (R_xlen_t k = 0; k < n; ++k) {
        double target = value[row(k)] - shift;
        while (j < n && value[row(j)] < target) ++j;
        result[row(k)] = j < n && value[row(j)] == target
            ? static_cast<int>(row(j) + 1) : NA_INTEGER;
    }
    return out;
}
