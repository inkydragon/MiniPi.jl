# SPDX-License-Identifier: MIT
import MiniPi:
    WORD_MAX,
    ensure_fft_tables, multiply_fft!
import MiniPi.FFT: 
    bit_reverse_indices,
    fft_forward!, fft_inverse!, fft_pointwise!,
    word_to_fft!, fft_to_word!,
    minimum_fft_size


@testset "bit_reverse_indices" begin
    @test bit_reverse_indices(2) == [1, 2]
    @test bit_reverse_indices(4) == [1, 3, 2, 4]
    @test bit_reverse_indices(8) == [1, 5, 3, 7, 2, 6, 4, 8]
    @test bit_reverse_indices(16) ==
        [1, 9, 5, 13, 3, 11, 7, 15, 2, 10, 6, 14, 4, 12, 8, 16]
end

@testset "fft_forward!" begin
    function test_fft(k, ref::Vector{Complex{T}}) where T
        len = 1 << k
        ta = complex(float(1:len))

        fft_forward!(ta, k)
        @test isapprox(ref, ta)
    end

    #=ref: FFTW.jl
    
    for k in 1:4
        len = 1 << k
        println(fft(1:len))
    end
    =#
    test_fft(1, [ 3+0im, -1+0im ])
    # TODO: bad bit-reversed order
    # ref-result output by: fft.cpp[FFT_CachedTwiddles.ipp]
    test_fft(2, [ 10+0im, -2+0im, -2+-2im, -2+2im ])
    test_fft(3, [
        36+0im, -4+0im,
        -4-4im, -4+4im,
        -4-9.65685424949238im, -4+1.65685424949238im,
        -4-1.65685424949238im, -4+9.65685424949238im
    ])
    test_fft(4, [
        136+0im, -8+0im,
        -8+-8im, -8+8im, 
        -8+-19.31370849898476im, -8+3.313708498984759im,
        -8+-3.313708498984759im, -8+19.31370849898476im,
        -8+-40.21871593700678im, -8+1.591298939037266im,
        -8+-5.345429103354391im, -8+11.97284610132391im,
        -8+-11.97284610132391im, -8+5.345429103354395im,
        -8+-1.591298939037266im, -8+40.21871593700678im,
    ])
end

@testset "fft_inverse!" begin
    function test_ifft(k, ref::Vector{Complex{T}}) where T
        len = 1 << k
        ta = complex(float(1:len))

        fft_inverse!(ta, k)
        @test isapprox(ref, ta)
    end

    #=ref: FFTW.jl
    
    for k in 1:4
        len = 1 << k
        println(ifft(1:len))
    end
    =#
    # TODO: bad bit-reversed order
    # ref-result output by: fft.cpp[FFT_CachedTwiddles.ipp]
    test_ifft(1, [3+0im, -1+0im])
    test_ifft(2, [10+0im, -1+1im, -4+0im, -1+-1im])
    test_ifft(3, [
        36+0im, -1+2.414213562373095im,
        -4+4im, -1+0.4142135623730949im,
        -16+0im, -1-0.4142135623730949im,
        -4+-4im, -1-2.414213562373095im
    ])
end

@testset "fft" begin
    t1 = ComplexF64[ 1:4... ]
    fft_forward!(t1, 2)
    fft_inverse!(t1, 2)
    
    @test_broken isapprox(zeros(ComplexF64, 4), t1)
end

@testset "fft_pointwise!" begin
    for k = 1:4
        len = 1 << k
        t = rand(ComplexF64, len)
        a = rand(ComplexF64, len)
        ref = t .* a

        @test isapprox(ref, fft_pointwise!(t, a, k))
    end
end

@testset "word_to_fft!, fft_to_word!" begin
    for k = 1:4
        len = 1 << k
        AL = trunc(UInt64, len/3)
        @assert len >= 3*AL

        T = zeros(ComplexF64, len)
        fill!(T, complex(NaN, NaN))
        A = rand(one(UInt32):WORD_MAX, AL)
        ref = deepcopy(A)

        word_to_fft!(T, k, A, AL)
        fft_to_word!(A, AL, T, k)

        @test isapprox(ref, A)
    end
end

@testset "multiply_fft!" begin
    @test ensure_fft_tables(zero(UInt64)) |> isnothing

    for AL = UInt64(1):UInt64(4),
        BL = UInt64(1)
        _, len = minimum_fft_size(AL+BL)

        C = zeros(UInt32, len)
        A = rand(one(UInt32):WORD_MAX, AL)
        ref = deepcopy(A)
        zero_A = zeros(UInt32, AL)
        B = ones(UInt32, BL)
        zero_B = zeros(UInt32, BL)

        # A == A * 1
        multiply_fft!(C, A, AL, B, BL)
        @test isapprox(ref, C[1:AL])

        # A == 1 * A
        A = deepcopy(ref)
        multiply_fft!(C, B, BL, A, AL)
        @test isapprox(ref, C[1:AL])

        # 0 == A * 0
        A = deepcopy(ref)
        multiply_fft!(C, A, AL, zero_B, BL)
        @test isapprox(zero_A, C[1:AL])

        # 0 == 0 * A
        A = deepcopy(ref)
        multiply_fft!(C, zero_B, BL, A, AL)
        @test isapprox(zero_A, C[1:AL])
    end
end
