import MiniPi.MiniBf
import MiniPi:
    WORD_SIZE, WORD_MAX,
    precision, exponent,
    ucmp,
    # String Conversion
    to_string_trimmed!, to_string_sci!, to_string,
    # Arithmetic
    negate!, mul, uadd, usub, add, sub,
    rcp, div


@testset "bigFloat.jl" begin

end

@testset "MiniBf" begin
    #= Types =#
    @test MiniBf <: AbstractFloat
    @test MiniBf() isa AbstractFloat
    
    #= Errors =#
    @test_throws DomainError MiniBf(WORD_SIZE)
    @test_throws DomainError MiniBf(typemax(UInt32))

    #= MiniBf() =#
    @test MiniBf() == MiniBf()
    @test MiniBf() == MiniBf(true, 0, 0x0000000000000000, UInt32[])

    #= MiniBf(::MiniBf) =#
    @test MiniBf(MiniBf()) == MiniBf()

    #= MiniBf(::UInt32, ::Bool=true) =#
    for x in UInt32[zero(UInt32), rand(1:WORD_MAX, 9)...],
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
    @test MiniBf(WORD_MAX) == MiniBf(WORD_MAX)
    @test MiniBf(UInt64(WORD_MAX)) == MiniBf(WORD_MAX)
    # Signed
    @test MiniBf(typemax(Int16)) == MiniBf(UInt32(typemax(Int16)))
    @test MiniBf(typemin(Int16)+1) == MiniBf(UInt32(32768-1), false)
    @test MiniBf(Int32(WORD_MAX)) == MiniBf(WORD_MAX)
    @test MiniBf(-Int32(WORD_MAX)) == MiniBf(WORD_MAX, false)
    @test MiniBf(Int64(WORD_MAX)) == MiniBf(WORD_MAX)
    @test MiniBf(-Int64(WORD_MAX)) == MiniBf(WORD_MAX, false)
    @test MiniBf(Int128(WORD_MAX)) == MiniBf(WORD_MAX)
    @test MiniBf(-Int128(WORD_MAX)) == MiniBf(WORD_MAX, false)
    @test MiniBf(BigInt(WORD_MAX)) == MiniBf(WORD_MAX)
    @test MiniBf(-BigInt(WORD_MAX)) == MiniBf(WORD_MAX, false)
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
        rand(1:WORD_MAX, 10)...,
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


#= String Conversion =#

@testset "to_string_trimmed!" begin
    function test_to_string_trimmed(x, to_digits=0)
        u8 = zeros(UInt8, to_digits)
        expo = to_string_trimmed!(u8, x, to_digits)
        expo, String(Char.(u8))
    end

    @test (0, "0") == test_to_string_trimmed(MiniBf(0))
    @test (0, "000000001") == test_to_string_trimmed(MiniBf(1))
    @test (0, "000000002") == test_to_string_trimmed(MiniBf(2))
    @test (0, "999999998") == test_to_string_trimmed(MiniBf(WORD_MAX-1))
    @test (0, "999999999") == test_to_string_trimmed(MiniBf(WORD_MAX))

    @test (0, "000000009999999990") == test_to_string_trimmed(mul(MiniBf(WORD_MAX), MiniBf(10)))
    str = string(Int(WORD_MAX) * Int(WORD_MAX))
    @test (0, str) == test_to_string_trimmed(mul(MiniBf(WORD_MAX), MiniBf(WORD_MAX)))
end

@testset "to_string_sci!" begin
    function test_to_string_sci(x, to_digits=0)
        u8 = zeros(UInt8, to_digits)
        to_string_sci!(u8, x, to_digits)
    end

    @test "0." == test_to_string_sci(MiniBf(0))
    @test "1." == test_to_string_sci(MiniBf(1))
    @test "2." == test_to_string_sci(MiniBf(2))
    @test "9.99999998 * 10^8" == test_to_string_sci(MiniBf(WORD_MAX-1))
    @test "9.99999999 * 10^8" == test_to_string_sci(MiniBf(WORD_MAX))

    @test "9.999999990 * 10^9" == test_to_string_sci(mul(MiniBf(WORD_MAX), MiniBf(10)))
    @test "9.9999999900 * 10^10" == test_to_string_sci(mul(MiniBf(WORD_MAX), MiniBf(100)))
    @test "9.99999998000000001 * 10^17" ==
        test_to_string_sci(mul(MiniBf(WORD_MAX), MiniBf(WORD_MAX)))
end

@testset "to_string" begin
    function test_to_string(x, to_digits=0)
        to_string(x, to_digits)
    end

    @test "0." == test_to_string(MiniBf(0))
    @test "1." == test_to_string(MiniBf(1))
    @test "2." == test_to_string(MiniBf(2))
    @test "999999998." == test_to_string(MiniBf(WORD_MAX-1))
    @test "999999999." == test_to_string(MiniBf(WORD_MAX))

    @test "9.999999990 * 10^9" == test_to_string(mul(MiniBf(WORD_MAX), MiniBf(10)))
    @test "9.9999999900 * 10^10" == test_to_string(mul(MiniBf(WORD_MAX), MiniBf(100)))
    @test "9.99999998000000001 * 10^17" ==
        test_to_string(mul(MiniBf(WORD_MAX), MiniBf(WORD_MAX)))
    
    # < 1
    @test "0.100000000000000000" == test_to_string(div(MiniBf(1), MiniBf(10), zero(UInt64)))
    @test "0.000001000000000000" == test_to_string(div(MiniBf(1), MiniBf(1000_000), zero(UInt64)))
    @test "0.000000001000000001" == test_to_string(div(MiniBf(1), MiniBf(WORD_MAX), zero(UInt64)))
    @test "0.000000001000000001" == test_to_string(div(MiniBf(1), MiniBf(WORD_MAX), zero(UInt64)))

    # pi
    @test "3.142857142857142304" == test_to_string(div(MiniBf(22), MiniBf(7), zero(UInt64)))
    @test "3.141592920353982370" == test_to_string(div(MiniBf(355), MiniBf(113), zero(UInt64)))
    
    # digits
    @test "3.14159" == test_to_string(div(MiniBf(355), MiniBf(113), zero(UInt64)), 5+1)
    @test "3.1415929203" == test_to_string(div(MiniBf(355), MiniBf(113), zero(UInt64)), 10+1)
    @test "3.141592920353982370" == test_to_string(div(MiniBf(355), MiniBf(113), zero(UInt64)), 20+1)
    @test "3.141592920353982370" == test_to_string(div(MiniBf(355), MiniBf(113), zero(UInt64)), 40+1)
end


@testset "negate!" begin
    @test negate!(MiniBf()) == MiniBf()
    @test negate!(MiniBf(1)) == MiniBf(-1)
    
    test_x = Int64[
        rand(UInt8, 10)...,
        rand(UInt16, 10)...,
        rand(1:WORD_MAX, 10)...,
    ]
    for x in test_x
        @test negate!(MiniBf(x)) == MiniBf(-x)
    end
end

@testset "mul" begin
    @test mul(MiniBf(0), 0x0) == MiniBf()
    @test mul(MiniBf(1), 0x0) == MiniBf()

    function test_commutative(x, y)
        @assert x >= 0
        u32_x = UInt32(x)
        u32_y = UInt32(y)
        @test mul(MiniBf(x), u32_y) == mul(MiniBf(y), u32_x)
        @test mul(MiniBf(-Int(x)), u32_y) == mul(MiniBf(-Int(y)), u32_x)
    end

    test_commutative(WORD_MAX, WORD_MAX)
    test_x = Int64[
        0:10...,
        rand(UInt8, 10)...,
        rand(UInt16, 10)...,
        rand(1:WORD_MAX, 10)...,
    ]
    for x in test_x
        u32_x = UInt32(x)
        @test mul(MiniBf(x), 0x0) == MiniBf(0)
        @test mul(MiniBf(x), 0x1) == MiniBf(x)
        @test mul(MiniBf(-x), 0x0) == MiniBf(0)
        @test mul(MiniBf(-x), 0x1) == MiniBf(-x)
        
        test_commutative(x, 0x0)
        test_commutative(x, 0x1)
        test_commutative(x, 0x2)
        test_commutative(x, WORD_MAX)
    end
end

@testset "uadd" begin
    @test uadd(MiniBf(0), MiniBf(0)) == MiniBf(0)
    @test uadd(MiniBf(1), MiniBf(0)) == MiniBf(1)

    function test_uadd_commutative(i64_x, i64_y, p=zero(UInt64))
        @assert i64_x > 0 && i64_y > 0
        x = MiniBf(i64_x)
        neg_x = MiniBf(-Int(i64_x))
        y = MiniBf(i64_y)
        neg_y = MiniBf(-Int(i64_y))

        pos_baseline_sum = uadd(x, y, p)
        @test pos_baseline_sum == uadd(y, x, p)
        @test pos_baseline_sum == uadd(x, neg_y, p)
        @test pos_baseline_sum == uadd(y, neg_x, p)

        neg_baseline_sum = uadd(neg_x, y, p)
        @test neg_baseline_sum == uadd(neg_y, x, p)
        @test neg_baseline_sum == uadd(neg_x, neg_y, p)
        @test neg_baseline_sum == uadd(neg_y, neg_x, p)
    end

    test_x = Int64[
        1:10...,
        rand(UInt8, 10)...,
        rand(UInt16, 10)...,
        rand(1:WORD_MAX, 10)...,
    ]
    for i64_x in test_x
        x = MiniBf(i64_x)
        neg_x = MiniBf(-i64_x)
        u32_x = UInt32(i64_x)

        @test uadd(x, MiniBf(0)) == x
        @test uadd(neg_x, MiniBf(0)) == neg_x
        @test uadd(MiniBf(0), x) == x
        @test uadd(MiniBf(0), neg_x) == x

        test_uadd_commutative(i64_x, 0x1)
        test_uadd_commutative(i64_x, 0x2)
        test_uadd_commutative(i64_x, u32_x)
        test_uadd_commutative(i64_x, WORD_MAX)
    end
end


@testset "usub" begin
    @test usub(MiniBf(0), MiniBf(0)) == MiniBf(0)
    @test usub(MiniBf(1), MiniBf(0)) == MiniBf(1)
    @test usub(MiniBf(1), MiniBf(1)) == MiniBf(0)
    @test usub(MiniBf(1), MiniBf(-1)) == MiniBf(0)

    test_x = Int64[
        1:10...,
        rand(UInt8, 10)...,
        rand(UInt16, 10)...,
        rand(1:WORD_MAX, 10)...,
    ]
    for i64_x in test_x
        x = MiniBf(i64_x)
        neg_x = MiniBf(-i64_x)
        u32_x = UInt32(i64_x)

        @test usub(x, MiniBf(0)) == x
        @test usub(x, x) == MiniBf(0)
        @test usub(x, neg_x) == MiniBf(0)
        @test usub(MiniBf(0), MiniBf(0)) == MiniBf(0)

        @test usub(MiniBf(i64_x+1), x) == MiniBf(1)
        @test usub(x, MiniBf(i64_x-1)) == MiniBf(1)
    end
end

@testset "add" begin
    @test add(MiniBf(0), MiniBf(0)) == MiniBf(0)
    @test add(MiniBf(1), MiniBf(0)) == MiniBf(1)
    @test add(MiniBf(1), MiniBf(1)) == MiniBf(2)

    @test add(MiniBf(1), MiniBf(-1)) == MiniBf(0)
    @test add(MiniBf(2), MiniBf(-1)) == MiniBf(1)

    @test add(MiniBf(-1), MiniBf(0)) == MiniBf(-1)
    @test add(MiniBf(-1), MiniBf(1)) == MiniBf(0)
end

@testset "sub" begin
    # diff sign
    @test sub(MiniBf(1), MiniBf(-1)) == MiniBf(2)
    @test sub(MiniBf(-1), MiniBf(1)) == MiniBf(-2)
    @test sub(MiniBf(-1), MiniBf(0)) == MiniBf(-1)

    # x > y
    @test sub(MiniBf(3), MiniBf(1)) == MiniBf(2)
    @test sub(MiniBf(-1), MiniBf(-3)) == MiniBf(2)

    # x < y
    @test sub(MiniBf(1), MiniBf(3)) == MiniBf(-2)
    @test sub(MiniBf(-1), MiniBf(1)) == MiniBf(-2)
end

@testset "mul(::MiniBf, ::MiniBf)" begin
    @test mul(MiniBf(0), MiniBf(0)) == MiniBf(0)
    @test mul(MiniBf(1), MiniBf(0)) == MiniBf(0)
    @test mul(MiniBf(0), MiniBf(-1)) == MiniBf(0)
    @test mul(MiniBf(1), MiniBf(1)) == MiniBf(1)
    @test mul(MiniBf(-1), MiniBf(-1)) == MiniBf(1)

    function test_mul_commutative(i64_x, i64_y)
        @assert i64_x >= 0 && i64_y >= 0
        x = MiniBf(i64_x)
        neg_x = MiniBf(-i64_x)
        y = MiniBf(i64_y)
        neg_y = MiniBf(-i64_y)

        @test mul(x, y) == mul(y, x)
        @test mul(neg_x, y) == mul(x, neg_y)
        @test mul(neg_x, y) == mul(neg_y, x)
        @test mul(neg_x, neg_y) == mul(neg_x, neg_y)
    end
    test_mul_commutative(x, y::Unsigned) = test_mul_commutative(x, Int(y))
    test_x = Int64[
        0:10...,
        rand(UInt8, 10)...,
        rand(UInt16, 10)...,
        rand(1:WORD_MAX, 10)...,
    ]
    for i64_x in test_x
        x = MiniBf(i64_x)
        neg_x = MiniBf(-i64_x)

        @test mul(x, MiniBf(0)) == MiniBf(0)
        @test mul(x, MiniBf(1)) == x
        @test mul(neg_x, MiniBf(0)) == MiniBf(0)
        @test mul(neg_x, MiniBf(1)) == neg_x

        test_mul_commutative(i64_x, 0x0)
        test_mul_commutative(i64_x, 0x1)
        test_mul_commutative(i64_x, 0x2)
        test_mul_commutative(i64_x, WORD_MAX)
    end
end

@testset "rcp" begin
    @test_throws DomainError rcp(MiniBf(0), zero(UInt64))

    @test rcp(MiniBf(1), zero(UInt64)) ==
        MiniBf(true, -1, 0x0000000000000002, UInt32[0x00000000, 0x00000001])
end

@testset "div" begin
    @test div(MiniBf(1), MiniBf(1), zero(UInt64)) ==
        MiniBf(true, -1, 0x0000000000000002, UInt32[0x00000000, 0x00000001, 0x00000000]) 
end
