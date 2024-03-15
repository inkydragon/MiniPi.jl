import MiniPi:
    bit_reverse_indices,
    fft_forward!, fft_inverse!


@testset "bit_reverse_indices" begin
    @test bit_reverse_indices(2) == [1, 2]
    @test bit_reverse_indices(4) == [1, 3, 2, 4]
    @test bit_reverse_indices(8) == [1, 5, 3, 7, 2, 6, 4, 8]
    @test bit_reverse_indices(16) ==
        [1, 9, 5, 13, 3, 11, 7, 15, 2, 10, 6, 14, 4, 12, 8, 16]
end

@testset "fft_forward!" begin
    # TODO: bad bit-reversed order
    r1 = ComplexF64[ 10+0im, -2+0im,-2+-2im, -2+2im ]
    t1 = ComplexF64[ 1:4... ]
    fft_forward!(t1, 2)
    @test isapprox(r1, t1)
end

@testset "fft_inverse!" begin
    # TODO: bad bit-reversed order
    r1 = ComplexF64[ 10+0im, -1+1im, -4+0im, -1+-1im ]
    t1 = ComplexF64[ 1:4... ]
    fft_inverse!(t1, 2)

    @test isapprox(r1, t1)
end

@testset "fft" begin
    t1 = ComplexF64[ 1:4... ]
    fft_forward!(t1, 2)
    fft_inverse!(t1, 2)
    
    @test_broken isapprox(zeros(ComplexF64, 4), t1)
end
