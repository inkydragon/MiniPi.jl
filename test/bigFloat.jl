import MiniPi.MiniBf
import MiniPi:
    precision, exponent,
    ucmp,
    # Arithmetic
    negate!

@testset "bigFloat.jl" begin

end

@testset "MiniBf" begin
    #= Types =#
    @test MiniBf <: AbstractFloat
    @test MiniBf() isa AbstractFloat

    #= MiniBf() =#
    @test MiniBf() == MiniBf()
    @test MiniBf() == MiniBf(true, 0, 0x0000000000000000, UInt32[])

    #= MiniBf(::MiniBf) =#
    @test MiniBf(MiniBf()) == MiniBf()

    #= MiniBf(::UInt32, ::Bool=true) =#
    for x in [zero(UInt32), rand(UInt32, 9)...],
        sign in [true, false]
        if iszero(x)
            @test MiniBf(x) == MiniBf(true, zero(Int64), zero(UInt64), UInt32[])
            @test MiniBf(x, sign) == MiniBf(true, zero(Int64), zero(UInt64), UInt32[])
            continue
        end

        # MiniBf(::UInt32)
        @testset "MiniBf($x)" begin
            @test MiniBf(x) == MiniBf(true, zero(Int64), one(UInt64), UInt32[x])
        end

        # MiniBf(::UInt32, ::Bool)
        @testset "MiniBf($x, $sign)" begin
            @test MiniBf(x, sign) == MiniBf(sign, zero(Int64), one(UInt64), UInt32[x])
        end
    end

    #= MiniBf(::Integer) =#
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
    @test MiniBf(Int128(typemax(UInt32))) == MiniBf(UInt32(4294967295))
    @test MiniBf(-Int128(typemax(UInt32))) == MiniBf(UInt32(4294967295), false)
    @test MiniBf(BigInt(typemax(UInt32))) == MiniBf(UInt32(4294967295))
    @test MiniBf(-BigInt(typemax(UInt32))) == MiniBf(UInt32(4294967295), false)
end

@testset "Base.precision" begin
    @test precision(MiniBf()) == 0
    @test precision(MiniBf(UInt32(1))) == 1
end

@testset "Base.exponent" begin
    @test exponent(MiniBf()) == 0
    @test exponent(MiniBf(UInt32(1))) == 0
end


function ucmp_gt(x, y)
    @test 1 == ucmp(MiniBf(x), MiniBf(y))
    @test 1 == ucmp(MiniBf(x), MiniBf(-y))
    @test 1 == ucmp(MiniBf(-x), MiniBf(y))
    @test 1 == ucmp(MiniBf(-x), MiniBf(-y))
end

function ucmp_eq(x, y)
    @test 0 == ucmp(MiniBf(x), MiniBf(y))
    @test 0 == ucmp(MiniBf(x), MiniBf(-y))
    @test 0 == ucmp(MiniBf(-x), MiniBf(y))
    @test 0 == ucmp(MiniBf(-x), MiniBf(-y))
end

function ucmp_lt(x, y)
    @test -1 == ucmp(MiniBf(x), MiniBf(y))
    @test -1 == ucmp(MiniBf(x), MiniBf(-y))
    @test -1 == ucmp(MiniBf(-x), MiniBf(y))
    @test -1 == ucmp(MiniBf(-x), MiniBf(-y))
end

@testset "ucmp" begin
    # gt >
    @test 1 == ucmp(MiniBf(1), MiniBf(0))
    ucmp_gt(1, 0)

    # eq ==
    @test 0 == ucmp(MiniBf(), MiniBf())
    @test 0 == ucmp(MiniBf(0), MiniBf())
    @test 0 == ucmp(MiniBf(1), MiniBf(1))
    ucmp_eq(0, 0)
    ucmp_eq(1, 1)

    # lt <
    @test -1 == ucmp(MiniBf(), MiniBf(1))
    ucmp_lt(0, 1)

    test_x = Int64[
        rand(UInt8, 10)...,
        rand(UInt16, 10)...,
        rand(UInt32, 10)...,
    ]
    for x in test_x
        # gt >
        ucmp_gt(x, x-1)
        ucmp_gt(x+1, x)

        # eq ==
        ucmp_eq(x-1, x-1)
        ucmp_eq(x, x)
        ucmp_eq(x+1, x+1)

        # lt <
        ucmp_lt(x-1, x)
        ucmp_lt(x, x+1)
    end
end

@testset "negate!" begin
    @test negate!(MiniBf()) == MiniBf()
    @test negate!(MiniBf(1)) == MiniBf(-1)
    
    test_x = Int64[
        rand(UInt8, 10)...,
        rand(UInt16, 10)...,
        rand(UInt32, 10)...,
    ]
    for x in test_x
        @test negate!(MiniBf(x)) == MiniBf(-x)
    end
end
