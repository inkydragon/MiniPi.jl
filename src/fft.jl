"""
A basic FFT multiply implementation. No optimizations are done.
"""
# import LinearAlgebra: rdiv!

function bit_reverse_indices(N::Integer)
    base = 2
    nbits = ceil(Int, log2(N))
    rev_indices = zeros(Int, N)

    for i in 0:N-1
        # 对索引 i 进行位反转
        rev = reverse(digits(i, base=base, pad=nbits))
        # 计算反转后的索引 from:  ?digits
        rev_index = sum(rev[k]*base^(k-1) for k=1:length(rev))
        rev_indices[i+1] = rev_index
    end

    # Julia 中索引从 1 开始
    rev_indices .+ 1
end


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
    ensure_fft_tables(cl::UInt64)

Ensure that the pre-computed twiddle factor table is large enough to handle
a product size of CL.
This method is not thread-safe with "multiply_fft()".
"""
function ensure_fft_tables(cl::UInt64) end

"""
    multiply_fft!(
        C::Vector{UInt32},
        A::Vector{UInt32}, al::UInt64,
        B::Vector{UInt32}, bl::UInt64
    )

Multiply A by B and store into C.

- `AL` and `BL` are the lengths of `A` and `B`.
- `AL + BL` is the length of `C`.
- `A`, `B`, and `C` point the start of a little-endian array big integer.
"""
function multiply_fft!(C::Vector{UInt32},
    A::Vector{UInt32}, al::UInt64,
    B::Vector{UInt32}, bl::UInt64)
end
