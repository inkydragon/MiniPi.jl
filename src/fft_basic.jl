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
