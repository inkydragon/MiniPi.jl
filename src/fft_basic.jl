"""
A basic FFT multiply implementation. No optimizations are done.
"""
# import LinearAlgebra: rdiv!


"""
    fft_forward!(T::Vector{ComplexF64}, k::Int)

This function performs a forward FFT of length 2^k.

This is a Decimation-in-Frequency (DIF) FFT.
The frequency domain output is in bit-reversed order.

Parameters:
- T:  Pointer to array.
- k:  2^k is the size of the transform
"""
function fft_forward!(T::AbstractVector{ComplexF64}, k::Int)
    if iszero(k)
        return
    end
    @assert k > 0

    len = UInt64(1) << k
    @assert length(T) >= len "len(T)=$(length(T)) must >= 2^k=$len"
    half_length = div(len, 2)

    omega = 2 * pi / len

    # Perform FFT reduction into two halves.
    for c in 1:half_length
        # Generate Twiddle Factor
        angle = omega * (c - 1)
        twiddle_factor = complex(cos(angle), sin(angle))

        # Grab elements
        a = T[c]
        b = T[c + half_length]

        # Perform butterfly
        T[c] = a + b
        T[c + half_length] = (a - b) * twiddle_factor
    end

    # Recursively perform FFT on lower elements.
    fft_forward!(T, k - 1)

    # Recursively perform FFT on upper elements.
    view_T = @view T[(half_length+1):end]
    fft_forward!(view_T, k - 1)

    T
end

"""
    fft_inverse(T::AbstractVector{ComplexF64}, k::Int)

This function performs an inverse FFT of length 2^k.

This is a Decimation-in-Time (DIT) FFT.
The frequency domain input must be in bit-reversed order.

Parameters:
- T: Pointer to array.
- k: 2^k is the size of the transform
"""
function fft_inverse!(T::AbstractVector{ComplexF64}, k::Int)
    _ifft_kernel!(T, k)

    len = 1 << k
    # XXX: bugfix:  T*1/n
    # rdiv!(T, len)
    T
end

function _ifft_kernel!(T::AbstractVector{ComplexF64}, k::Int)
    if iszero(k)
        return
    end
    @assert k > 0

    len = UInt64(1) << k
    @assert length(T) >= len "len(T)=$(length(T)) must >= 2^k=$len"
    half_length = div(len, 2)

    omega = -2 * pi / len

    # Recursively perform FFT on lower elements.
    _ifft_kernel!(T, k - 1)

    # Recursively perform FFT on upper elements.
    view_T = @view T[(half_length+1):end]
    _ifft_kernel!(view_T, k - 1)

    # Perform FFT reduction into two halves.
    for c in 1:half_length
        # Generate Twiddle Factor
        angle = omega * (c - 1)
        twiddle_factor = complex(cos(angle), sin(angle))

        # Grab elements
        a = T[c]
        b = T[c + half_length] * twiddle_factor

        # Perform butterfly
        T[c] = a + b
        T[c + half_length] = a - b
    end

    T
end

"""
    fft_pointwise(T::Vector{ComplexF64}, A::Vector{ComplexF64}, k::Int)

Performs pointwise multiplications of two FFT arrays.

Parameters:
- T: Pointer to array.
- k: 2^k is the size of the transform
"""
function fft_pointwise!(T::Vector{ComplexF64}, A::Vector{ComplexF64}, k::Int)
    len = 1 << k
    @assert length(T) >= len && length(A) >= len

    for i in 1:len
        T[i] *= A[i]
    end

    T
end


#= Helper functions =#

const WORD_DIGITS = 1000

function _check_fft_length(T::Vector{ComplexF64}, k::Int, A::Vector{UInt32}, AL::UInt64)
    fft_length = 1 << k

    @assert length(T) >= fft_length

    @assert length(A) >= AL

    # Since there are 9 digits per word and we want to put 3 digits per
    # point, the length of the transform must be at least 3 times the word
    # length of the input.
    word_arr_length = 3 * AL
    if fft_length < word_arr_length
        fmt_str = "fft_length($fft_length) should >= 3*AL ($word_arr_length)"
        throw(ArgumentError("FFT length is too small. $fmt_str"))
    end
end

"""
    word_to_fft(T::Vector{ComplexF64}, k::Int, A::Vector{UInt32}, AL::UInt64)

Convert word array into FFT array.
Put 3 decimal digits per complex point.

Parameters:
- T:  FFT array
- k:  2^k is the size of the transform
- A:  word array
- AL: length of word array
"""
function word_to_fft!(T::Vector{ComplexF64}, k::Int, A::Vector{UInt32}, AL::UInt64)
    fft_length = 1 << k

    _check_fft_length(T, k, A, AL)

    # Convert
    for i = 1:AL
        t_idx = i*3 - 2
        word = A[i]

        T[t_idx] = word % WORD_DIGITS
        word = div(word, WORD_DIGITS)
        T[t_idx+1] = word % WORD_DIGITS
        word = div(word, WORD_DIGITS)
        T[t_idx+2] = word % WORD_DIGITS
    end
    
    # Pad the rest with zeros.
    T[(3*AL+1):fft_length] .= zero(ComplexF64)

    T
end

"""
    fft_to_word!(A::Vector{UInt32}, AL::UInt64, T::Vector{ComplexF64}, k::Int)

Convert FFT array back to word array.
Perform rounding and carryout.

Parameters:
- A:  word array
- AL: length of word array
- T:  FFT array
- k:  2^k is the size of the transform
"""
function fft_to_word!(A::Vector{UInt32}, AL::UInt64, T::Vector{ComplexF64}, k::Int, scale=1.0)
    _check_fft_length(T, k, A, AL)

    # Round and carry out.
    carry = zero(UInt64)
    for i = 1:AL
        t_idx = i*3 - 2
    
        # digits[1]
        f_point = real(T[t_idx]) * scale        #  Load and scale
        i_point = trunc(UInt64, f_point + 0.5)  #  Round
        carry += i_point                        #  Add to carry
        word = carry % WORD_DIGITS              #  Get 3 digits.
        carry = div(carry, WORD_DIGITS)
    
        # digits[2]
        f_point = real(T[t_idx+1]) * scale
        i_point = trunc(UInt64, f_point + 0.5)
        carry += i_point
        word += (carry % WORD_DIGITS) * WORD_DIGITS
        carry = div(carry, WORD_DIGITS)

        # digits[3]
        f_point = real(T[t_idx+2]) * scale
        i_point = trunc(UInt64, f_point + 0.5)
        carry += i_point
        word += (carry % WORD_DIGITS) * WORD_DIGITS * WORD_DIGITS
        carry = div(carry, WORD_DIGITS)

        A[i] = word
    end

    A
end

function unscale_fft_to_word!(A::Vector{UInt32}, AL::UInt64, T::Vector{ComplexF64}, k::Int)
    # Compute Scaling Factor
    fft_length = 1 << k
    scale = 1.0 / fft_length

    fft_to_word!(A, AL, T, k, scale)
end


"""
No-Op for basic impl.
"""
function ensure_fft_tables(cl::UInt64)
    # No-Op
end

"""
Determine minimum FFT size.
"""
function minimum_fft_size(cl::UInt64)
    k = 0
    len = one(UInt64)
    while len < 3*cl
        len <<= 1
        k += 1
    end

    k, len
end

function multiply_fft!(C::Vector{UInt32},
        A::Vector{UInt32}, AL::UInt64,
        B::Vector{UInt32}, BL::UInt64,
    )
    CL = AL + BL

    k, len = minimum_fft_size(CL)

    # Allocate FFT arrays
    Ta = zeros(ComplexF64, len)
    Tb = zeros(ComplexF64, len)

    # Perform a convolution using FFT.
    # Yeah, this is slow for small sizes, but it's asympotically optimal.

    # 3 digits per point is small enough to not encounter round-off error
    # until a transform size of 2^30.
    # A transform length of 2^29 allows for the maximum product size to be
    # 2^29 * 3 = 1, 610, 612, 736 decimal digits.
    if k > 29
        throw(ArgumentError("FFT size limit exceeded."))
    end

    word_to_fft!(Ta, k, A, AL)  # Convert 1st operand
    word_to_fft!(Tb, k, B, BL)  # Convert 2nd operand

    fft_forward!(Ta, k)         # Transform 1st operand
    fft_forward!(Tb, k)         # Transform 2nd operand
    fft_pointwise!(Ta, Tb, k)   # Pointwise multiply
    fft_inverse!(Ta, k)         # Perform inverse transform.

    unscale_fft_to_word!(C, CL, Ta, k)  # Convert back to word array.

    C
end
