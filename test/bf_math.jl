import MiniPi.MiniBf
import MiniPi:
    WORD_SIZE, WORD_MAX,
    MiniBf,
    # Arithmetic
    negate!, mul, uadd, usub, add, sub,
    rcp, div


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
