#pragma once

#include "cpp11.hpp"

// Read-only access to a logical, integer or double vector as doubles, with
// NA as NA_real_, as as.double() would give, without copying the vector.
class numeric_view {
    const double* real_ = nullptr;
    const int* integer_ = nullptr;

public:
    explicit numeric_view(SEXP x)
    {
        switch (TYPEOF(x)) {
        case REALSXP: real_ = REAL_RO(x); break;
        case INTSXP: integer_ = INTEGER_RO(x); break;
        case LGLSXP: integer_ = LOGICAL_RO(x); break;
        default: cpp11::stop("Numeric kernels require logical, integer or double vectors.");
        }
    }

    double operator[](R_xlen_t i) const
    {
        if (real_) return real_[i];
        return integer_[i] == NA_INTEGER ? NA_REAL : static_cast<double>(integer_[i]);
    }
};
