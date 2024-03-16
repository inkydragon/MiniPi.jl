
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
Ensure that the pre-computed twiddle factor table is large enough to handle
a product size of CL.
"""
function ensure_fft_tables end

"""
Multiply A by B and store into C.
"""
function multiply_fft! end
