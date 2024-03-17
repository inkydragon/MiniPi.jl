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
    test_uadd_commutative(2, 0x3, UInt64(9))

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

@testset "mul(::MiniBf, ::MiniBf, ::UInt64)" begin
    @test mul(MiniBf(0), MiniBf(0)) == MiniBf(0)
    @test mul(MiniBf(1), MiniBf(0)) == MiniBf(0)
    @test mul(MiniBf(0), MiniBf(-1)) == MiniBf(0)
    @test mul(MiniBf(1), MiniBf(1)) == MiniBf(1)
    @test mul(MiniBf(-1), MiniBf(-1)) == MiniBf(1)

    function test_mul_commutative(i64_x, u64_y, p=0)
        @assert i64_x >= 0 && u64_y >= 0
        i64_y = Int(u64_y)
        x = MiniBf(i64_x)
        neg_x = MiniBf(-i64_x)
        y = MiniBf(i64_y)
        neg_y = MiniBf(-i64_y)
        p = UInt64(p)

        @testset "mul($i64_x, $i64_y, $(Int(p)))" begin
            @test mul(x, y, p) == mul(y, x, p)
            @test mul(neg_x, y, p) == mul(x, neg_y, p)
            @test mul(neg_x, y, p) == mul(neg_y, x, p)
            @test mul(neg_x, neg_y, p) == mul(neg_x, neg_y, p)
        end
    end
    test_mul_commutative(x, y::Unsigned) = test_mul_commutative(x, Int(y))
    test_x = Int64[
        0:10...,
        rand(UInt8, 10)...,
        rand(UInt16, 10)...,
        rand(1:WORD_MAX, 10)...,
    ]
    for i64_x in test_x,
        p = [0, 18]
        x = MiniBf(i64_x)
        neg_x = MiniBf(-i64_x)

        @test mul(x, MiniBf(0)) == MiniBf(0)
        @test mul(x, MiniBf(1)) == x
        @test mul(neg_x, MiniBf(0)) == MiniBf(0)
        @test mul(neg_x, MiniBf(1)) == neg_x

        test_mul_commutative(i64_x, 0x0, p)
        test_mul_commutative(i64_x, 0x1, p)
        test_mul_commutative(i64_x, 0x2, p)
        test_mul_commutative(i64_x, WORD_MAX, p)
    end
end

const test_cpp_rcp_ref = String[
    "1.000000000",
    "0.500000000000000000",
    "0.333333333333333312",
    "0.250000000000000000",
    "0.200000000000000000",
    "0.166666666666666656",
    "0.142857142857142832",
    "0.125000000000000000",
    "0.111111111111111104",
    "0.100000000000000000",
    "0.090909090909090912",
    "0.083333333333333328",
    "0.076923076923076928",
    "0.071428571428571416",
    "0.066666666666666664",
    "0.062500000000000000",
    "0.058823529411764704",
    "0.055555555555555552",
    "0.052631578947368424",
    "0.050000000000000000",
    "0.047619047619047616",
    "0.045454545454545456",
    "0.043478260869565216",
    "0.041666666666666664",
    "0.040000000000000000",
    "0.038461538461538464",
    "0.037037037037037040",
    "0.035714285714285708",
    "0.034482758620689652",
    "0.033333333333333332",
    "0.032258064516129032",
    "0.031250000000000000",
    "0.030303030303030304",
    "0.029411764705882352",
    "0.028571428571428572",
    "0.027777777777777776",
    "0.027027027027027028",
    "0.026315789473684212",
    "0.025641025641025640",
    "0.025000000000000000",
    "0.024390243902439024",
    "0.023809523809523808",
]

@testset "rcp" begin
    @test_throws DomainError rcp(MiniBf(0), zero(UInt64))

    @test rcp(MiniBf(1), zero(UInt64)) ==
        MiniBf(true, -1, 0x0000000000000002, UInt32[0x00000000, 0x00000001])

    for (i, val) in enumerate(test_cpp_rcp_ref)
        test_to_string(val, rcp(MiniBf(i), zero(UInt64)))
    end
end

@testset "div" begin
    @test div(MiniBf(1), MiniBf(1), zero(UInt64)) ==
        MiniBf(true, -1, 0x0000000000000002, UInt32[0x00000000, 0x00000001, 0x00000000]) 
end
