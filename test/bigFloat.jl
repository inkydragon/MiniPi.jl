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
    
    # Integer input
    # Bool
    @test MiniBf(true) == MiniBf(UInt32(1))
    @test MiniBf(false) == MiniBf(UInt32(0))
    # Unsigned
    @test MiniBf(0xffff) == MiniBf(UInt32(0xffff))
    @test MiniBf(0xffffffff) == MiniBf(UInt32(0xffffffff))
    @test MiniBf(0x00000000ffffffff) == MiniBf(UInt32(0x00000000ffffffff))
    # Signed
    @test MiniBf(typemax(Int16)) == MiniBf(UInt32(typemax(Int16)))
    @test MiniBf(typemin(Int16)+1) == MiniBf(UInt32(32768-1), false)
    @test MiniBf(typemax(Int32)) == MiniBf(UInt32(typemax(Int32)))
    @test MiniBf(typemin(Int32)+1) == MiniBf(UInt32(2147483648-1), false)
    @test MiniBf(Int64(typemax(UInt32))) == MiniBf(UInt32(4294967295))
    @test MiniBf(-Int64(typemax(UInt32))) == MiniBf(UInt32(4294967295), false)
    @test MiniBf(BigInt(Int64(typemax(UInt32)))) == MiniBf(UInt32(4294967295))
    @test MiniBf(-BigInt(Int64(typemax(UInt32)))) == MiniBf(UInt32(4294967295), false)

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

@testset "Base.precision" begin
    @test precision(MiniBf()) == 0
    @test precision(MiniBf(UInt32(1))) == 1
end

@testset "Base.exponent" begin
    @test exponent(MiniBf()) == 0
    @test exponent(MiniBf(UInt32(1))) == 0
end
