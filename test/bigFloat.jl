import MiniPi.MiniBf
import MiniPi:
    precision, exponent

@testset "bigFloat.jl" begin

end

@testset "MiniBf" begin
    # Types
    @test MiniBf <: AbstractFloat
    @test MiniBf() isa AbstractFloat

    @test MiniBf() == MiniBf()
    @test MiniBf(MiniBf()) == MiniBf()
    @test MiniBf() == MiniBf(true, 0, 0x0000000000000000, UInt32[])

    for x in [zero(UInt32), rand(UInt32, 9)...],
        sign in [true, false]
        @testset "MiniBf($x, $sign)" begin
            if iszero(x)
                @test MiniBf(x, sign) == MiniBf(true, zero(Int64), zero(UInt64), UInt32[])
            else
                @test MiniBf(x, sign) == MiniBf(sign, zero(Int64), one(UInt64), UInt32[x])
            end
        end
    end
end

@testset "precision" begin
    @test precision(MiniBf()) == 0
    @test precision(MiniBf(UInt32(1))) == 1
end

@testset "exponent" begin
    @test exponent(MiniBf()) == 0
    @test exponent(MiniBf(UInt32(1))) == 0
end
