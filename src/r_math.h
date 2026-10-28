#pragma once

#include <cmath>
#if defined(__SSE2__)
#include <emmintrin.h>
#endif

// sqrt() of a double, correctly rounded as in R's own optimised build. Some
// libm implementations (mingw's x87 routine, called without optimisation)
// round twice, so SSE2 builds use the hardware instruction directly.
inline double r_sqrt(double x)
{
#if defined(__SSE2__)
    return _mm_cvtsd_f64(_mm_sqrt_sd(_mm_set_sd(x), _mm_set_sd(x)));
#else
    return std::sqrt(x);
#endif
}
