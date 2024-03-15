import MiniPi:
    bit_reverse_indices

@testset "fft" begin

end

@testset "bit_reverse_indices" begin
    @test bit_reverse_indices(2) == [1, 2]
    @test bit_reverse_indices(4) == [1, 3, 2, 4]
    @test bit_reverse_indices(8) == [1, 5, 3, 7, 2, 6, 4, 8]
    @test bit_reverse_indices(16) ==
        [1, 9, 5, 13, 3, 11, 7, 15, 2, 10, 6, 14, 4, 12, 8, 16]
end

