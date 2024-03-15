
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
