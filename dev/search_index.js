var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = MiniPi","category":"page"},{"location":"#MiniPi","page":"Home","title":"MiniPi","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for MiniPi.","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [MiniPi]","category":"page"},{"location":"#MiniPi.EXTRA_PRECISION","page":"Home","title":"MiniPi.EXTRA_PRECISION","text":"Precision increase step.\n\n\n\n\n\n","category":"constant"},{"location":"#MiniPi.WORD_MAX","page":"Home","title":"MiniPi.WORD_MAX","text":"Word max\n\n\n\n\n\n","category":"constant"},{"location":"#MiniPi.WORD_SIZE","page":"Home","title":"MiniPi.WORD_SIZE","text":"Word size = 10^9\n\n\n\n\n\n","category":"constant"},{"location":"#MiniPi.MiniBf","page":"Home","title":"MiniPi.MiniBf","text":"MiniBf(x::UInt32, sign=true)\n\nConstruct a BigFloat with a value of x and the specified sign.\n\n\n\n\n\n","category":"type"},{"location":"#MiniPi.MiniBf-2","page":"Home","title":"MiniPi.MiniBf","text":"The Big Floating-point object. It represents an arbitrary precision floating-point number.\n\nIts numerical value is equal to:\n\n    word = 10^9\n    word^exp * (T[0] + T[1]*word + T[2]*word^2 + ... + T[L - 1]*word^(L - 1))\n\nT is an array of 32-bit integers. Each integer stores 9 decimal digits and must always have a value in the range [0, 999999999].\n\nT[L - 1] must never be zero. \n\nThe number is positive when (sign = true) and negative when (sign = false). Zero is represented as (sign = true) and (len = 0).\n\n\n\n\n\n","category":"type"},{"location":"#Base.Math.exponent-Tuple{MiniPi.MiniBf}","page":"Home","title":"Base.Math.exponent","text":"Base.exponent(x::MiniBf)\n\nReturns the exponent of the number in words.\n\nNote that each word is 9 decimal digits.\n\n\n\n\n\n","category":"method"},{"location":"#Base.div-Tuple{MiniPi.MiniBf, MiniPi.MiniBf, UInt64}","page":"Home","title":"Base.div","text":"Base.div(x::MiniBf, y::UInt32, p::UInt64)\n\nDivision\n\nDepend on: mul, rcp\n\n\n\n\n\n","category":"method"},{"location":"#Base.precision-Tuple{MiniPi.MiniBf}","page":"Home","title":"Base.precision","text":"Base.precision(x::MiniBf)\n\nReturns the precision of the number in words.\n\nNote that each word is 9 decimal digits.\n\n\n\n\n\n","category":"method"},{"location":"#MiniPi.Pi","page":"Home","title":"MiniPi.Pi","text":"Compute Pi using the Chudnovsky Formula.\n\n\n\n\n\n","category":"function"},{"location":"#MiniPi.add","page":"Home","title":"MiniPi.add","text":"add(x::MiniBf, y::MiniBf, p=zero(UInt64))\n\nAddition\n\nThe target precision is p.\n\nIf (p = 0), then no truncation is done. The entire operation is done at maximum precision with no data loss.\n\n\n\n\n\n","category":"function"},{"location":"#MiniPi.ensure_fft_tables","page":"Home","title":"MiniPi.ensure_fft_tables","text":"Ensure that the pre-computed twiddle factor table is large enough to handle a product size of CL.\n\nThis method is not thread-safe with \"multiply_FFT()\".\n\n\n\n\n\n","category":"function"},{"location":"#MiniPi.ensure_fft_tables-Tuple{UInt64}","page":"Home","title":"MiniPi.ensure_fft_tables","text":"No-Op for basic impl.\n\n\n\n\n\n","category":"method"},{"location":"#MiniPi.fft_forward!-Tuple{AbstractVector{ComplexF64}, Int64}","page":"Home","title":"MiniPi.fft_forward!","text":"fft_forward!(T::Vector{ComplexF64}, k::Int)\n\nThis function performs a forward FFT of length 2^k.\n\nThis is a Decimation-in-Frequency (DIF) FFT. The frequency domain output is in bit-reversed order.\n\nParameters:\n\nT:  Pointer to array.\nk:  2^k is the size of the transform\n\n\n\n\n\n","category":"method"},{"location":"#MiniPi.fft_inverse!-Tuple{AbstractVector{ComplexF64}, Int64}","page":"Home","title":"MiniPi.fft_inverse!","text":"fft_inverse(T::AbstractVector{ComplexF64}, k::Int)\n\nThis function performs an inverse FFT of length 2^k.\n\nThis is a Decimation-in-Time (DIT) FFT. The frequency domain input must be in bit-reversed order.\n\nParameters:\n\nT: Pointer to array.\nk: 2^k is the size of the transform\n\n\n\n\n\n","category":"method"},{"location":"#MiniPi.fft_pointwise!-Tuple{Vector{ComplexF64}, Vector{ComplexF64}, Int64}","page":"Home","title":"MiniPi.fft_pointwise!","text":"fft_pointwise(T::Vector{ComplexF64}, A::Vector{ComplexF64}, k::Int)\n\nPerforms pointwise multiplications of two FFT arrays.\n\nParameters:\n\nT: Pointer to array.\nk: 2^k is the size of the transform\n\n\n\n\n\n","category":"method"},{"location":"#MiniPi.fft_to_word!","page":"Home","title":"MiniPi.fft_to_word!","text":"fft_to_word!(A::Vector{UInt32}, AL::UInt64, T::Vector{ComplexF64}, k::Int)\n\nConvert FFT array back to word array. Perform rounding and carryout.\n\nParameters:\n\nA:  word array\nAL: length of word array\nT:  FFT array\nk:  2^k is the size of the transform\n\n\n\n\n\n","category":"function"},{"location":"#MiniPi.invsqrt-Tuple{UInt32, UInt64}","page":"Home","title":"MiniPi.invsqrt","text":"invsqrt(x::UInt32, p::UInt64)\n\nCompute inverse square root using Newton's Method.\n\n            (  r0^2 * x - 1  )\n  r1 = r0 - (----------------) * r0\n            (       2        )\n\nDepend on: invsqrt, sub, mul\n\n\n\n\n\n","category":"method"},{"location":"#MiniPi.minimum_fft_size-Tuple{UInt64}","page":"Home","title":"MiniPi.minimum_fft_size","text":"Determine minimum FFT size.\n\n\n\n\n\n","category":"method"},{"location":"#MiniPi.mul","page":"Home","title":"MiniPi.mul","text":"mul(x::MiniBf, y::MiniBf, p=zero(UInt64))\n\nMultiplication\n\nThe target precision is p. If (p = 0), then no truncation is done. The entire operation is done at maximum precision with no data loss.\n\nDepend on: multiply_fft!\n\n\n\n\n\n","category":"function"},{"location":"#MiniPi.mul-Tuple{MiniPi.MiniBf, UInt32}","page":"Home","title":"MiniPi.mul","text":"mul(x::MiniBf, y::UInt32)\n\nMultiply by a 32-bit unsigned integer.\n\n\n\n\n\n","category":"method"},{"location":"#MiniPi.multiply_fft!","page":"Home","title":"MiniPi.multiply_fft!","text":"multiply_fft!(\n    C::Vector{UInt32},\n    A::Vector{UInt32}, AL::UInt64,\n    B::Vector{UInt32}, BL::UInt64,\n)\n\nMultiply A by B and store into C.\n\nAL and BL are the lengths of A and B.\nAL + BL is the length of C.\nA, B, and C point the start of a little-endian array big integer.\n\n\n\n\n\n","category":"function"},{"location":"#MiniPi.negate!-Tuple{MiniPi.MiniBf}","page":"Home","title":"MiniPi.negate!","text":"negate!(x::MiniBf)\n\nNegate this number.\n\n\n\n\n\n","category":"method"},{"location":"#MiniPi.pi_bsr-Tuple{UInt32, UInt32, UInt64}","page":"Home","title":"MiniPi.pi_bsr","text":"Binary Splitting recursion for the Chudnovsky Formula.\n\n\n\n\n\n","category":"method"},{"location":"#MiniPi.rcp-Tuple{MiniPi.MiniBf, UInt64}","page":"Home","title":"MiniPi.rcp","text":"rcp(x::MiniBf, p::UInt64)\n\nCompute reciprocal using Newton's Method.\n\nr1 = r0 - (r0 * x - 1) * r0\n\nDepend on: rcp, sub, mul\n\n\n\n\n\n","category":"method"},{"location":"#MiniPi.sub","page":"Home","title":"MiniPi.sub","text":"sub(x::MiniBf, y::MiniBf, p=zero(UInt64))\n\nSubtraction: x - y,  The target precision is p.\n\nIf (p = 0), then no truncation is done. The entire operation is done at maximum precision with no data loss.\n\n\n\n\n\n","category":"function"},{"location":"#MiniPi.to_string-Tuple{MiniPi.MiniBf, Int64}","page":"Home","title":"MiniPi.to_string","text":"to_string(x::MiniBf, to_digits::Int64)\n\nConvert this number to a string. Auto-select format type.\n\n\n\n\n\n","category":"method"},{"location":"#MiniPi.to_string_sci!-Tuple{Vector{UInt8}, MiniPi.MiniBf, Int64}","page":"Home","title":"MiniPi.to_string_sci!","text":"to_string_sci!(u8::Vector{UInt8}, x::MiniBf, to_digits::Int64)\n\nConvert to string in scientific notation.\n\n\n\n\n\n","category":"method"},{"location":"#MiniPi.to_string_trimmed!-Tuple{Vector{UInt8}, MiniPi.MiniBf, Int64}","page":"Home","title":"MiniPi.to_string_trimmed!","text":"to_string_trimmed!(str::Vector{UInt8}, x::MiniBf, to_digits::Int64)\n\nConverts this object to a string with \"digits\" significant figures.\n\nAfter calling this function, the following expression is equal to the numeric value of this object. (after truncation of precision)     str + \" * 10^\" + (return value)\n\n\n\n\n\n","category":"method"},{"location":"#MiniPi.uadd","page":"Home","title":"MiniPi.uadd","text":"uadd(x::MiniBf, y::MiniBf, p=zero(UInt64))\n\nPerform addition ignoring the sign of the two operands.\n\n\n\n\n\n","category":"function"},{"location":"#MiniPi.ucmp-Tuple{MiniPi.MiniBf, MiniPi.MiniBf}","page":"Home","title":"MiniPi.ucmp","text":"ucmp(x::MiniBf, y::MiniBf)\n\nCompare function that ignores the sign.\n\nThis is needed to determine which direction subtractions will go.\n\n\n\n\n\n","category":"method"},{"location":"#MiniPi.usub","page":"Home","title":"MiniPi.usub","text":"usub(xx::MiniBf, yy::MiniBf, p=zero(UInt64))\n\nPerform subtraction ignoring the sign of the two operands.\n\n\"this\" must be greater than or equal to y. Otherwise, the behavior is undefined.\n\n\n\n\n\n","category":"function"},{"location":"#MiniPi.word_at-Tuple{MiniPi.MiniBf, Int64}","page":"Home","title":"MiniPi.word_at","text":"word_at(x::MiniBf, mag::Int64)\n\nReturns the word at the mag'th digit place.\n\nThis is useful for additions where you need to access a specific \"digit place\" of the operand without having to worry if it's out-of-bounds.\n\nThis function is mathematically equal to:\n\n(return value) = floor(this * (10^9)^-mag) % 10^9\n\nTODO: use getindex\n\n\n\n\n\n","category":"method"},{"location":"#MiniPi.word_to_fft!-Tuple{Vector{ComplexF64}, Int64, Vector{UInt32}, UInt64}","page":"Home","title":"MiniPi.word_to_fft!","text":"word_to_fft(T::Vector{ComplexF64}, k::Int, A::Vector{UInt32}, AL::UInt64)\n\nConvert word array into FFT array. Put 3 decimal digits per complex point.\n\nParameters:\n\nT:  FFT array\nk:  2^k is the size of the transform\nA:  word array\nAL: length of word array\n\n\n\n\n\n","category":"method"}]
}
