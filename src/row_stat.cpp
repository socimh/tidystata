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
