// SPDX-License-Identifier: CC0-1.0
/* FFT.cpp
 *
 * Author           : Alexander J. Yee
 * Date Created     : 07/09/2013
 * Last Modified    : 03/22/2015
 * 
 */

//  Pick your optimizations.
#define MINI_PI_CACHED_TWIDDLES
// #define MINI_PI_SSE3    //  Includes caching of twiddle factors.

#if 0
#elif defined MINI_PI_SSE3
#include "FFT_SSE3.ipp"
#elif defined MINI_PI_CACHED_TWIDDLES
#include "FFT_CachedTwiddles.ipp"
#else
#include "FFT_Basic.ipp"
#endif

#include <iostream>
#include <vector>
#include <complex>

std::vector<std::complex<double>> generateComplexVector(int n) {
    std::vector<std::complex<double>> result;
    for (int i = 1; i <= n; ++i) {
        result.push_back(std::complex<double>(i, 0));
    }
    return result;
}
void print_vec_cf64(std::vector<std::complex<double>> vec) {
    for (const auto& num : vec) {
        // printf("%.16g+%.16gim, ", num.real(), num.imag());
        printf("%.4g+%.4gim, ", num.real(), num.imag());
    }
    puts("");
}

int main() {
    auto k = 2;
    
    for (int k=1; k <= 3; k++) {
            auto len = 0x1 << k;
        auto Ta = generateComplexVector(len);

        Mini_Pi::ensure_FFT_tables(k);

        printf("k=%d;  len=%d;\n", k, len);

        puts("fft_forward(1..len):");
        printf("    in:   "); print_vec_cf64(Ta);
            Mini_Pi::fft_forward(Ta.data(), k);
        printf("    out:  "); print_vec_cf64(Ta);

        puts("fft_inverse(fft_forward(1..len))");
        printf("    in:   "); print_vec_cf64(Ta);
            Mini_Pi::fft_inverse(Ta.data(), k);
        printf("    out:  "); print_vec_cf64(Ta);

        puts("fft_inverse(1..len):");
        Ta = generateComplexVector(len);
        printf("    in:   "); print_vec_cf64(Ta);
            Mini_Pi::fft_inverse(Ta.data(), k);
        printf("    out:  "); print_vec_cf64(Ta);
        
        puts("");
    }

    return 0;
}
