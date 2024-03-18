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

const test_cpp_mul_u32_ref = [
    ("999999998.", "9.99999997000000002 * 10^17"),
    ("1.999999996 * 10^9", "1.999999994000000004 * 10^18"),
    ("2.999999994 * 10^9", "2.999999991000000006 * 10^18"),
    ("3.999999992 * 10^9", "3.999999988000000008 * 10^18"),
    ("4.999999990 * 10^9", "4.999999985000000010 * 10^18"),
    ("5.999999988 * 10^9", "5.999999982000000012 * 10^18"),
    ("6.999999986 * 10^9", "6.999999979000000014 * 10^18"),
    ("7.999999984 * 10^9", "7.999999976000000016 * 10^18"),
    ("8.999999982 * 10^9", "8.999999973000000018 * 10^18"),
    ("9.999999980 * 10^9", "9.999999970000000020 * 10^18"),
    ("1.0999999978 * 10^10", "1.0999999967000000022 * 10^19"),
    ("1.1999999976 * 10^10", "1.1999999964000000024 * 10^19"),
    ("1.2999999974 * 10^10", "1.2999999961000000026 * 10^19"),
    ("1.3999999972 * 10^10", "1.3999999958000000028 * 10^19"),
    ("1.4999999970 * 10^10", "1.4999999955000000030 * 10^19"),
    ("1.5999999968 * 10^10", "1.5999999952000000032 * 10^19"),
    ("1.6999999966 * 10^10", "1.6999999949000000034 * 10^19"),
    ("1.7999999964 * 10^10", "1.7999999946000000036 * 10^19"),
    ("1.8999999962 * 10^10", "1.8999999943000000038 * 10^19"),
    ("1.9999999960 * 10^10", "1.9999999940000000040 * 10^19"),
    ("2.0999999958 * 10^10", "2.0999999937000000042 * 10^19"),
    ("2.1999999956 * 10^10", "2.1999999934000000044 * 10^19"),
    ("2.2999999954 * 10^10", "2.2999999931000000046 * 10^19"),
    ("2.3999999952 * 10^10", "2.3999999928000000048 * 10^19"),
    ("2.4999999950 * 10^10", "2.4999999925000000050 * 10^19"),
    ("2.5999999948 * 10^10", "2.5999999922000000052 * 10^19"),
    ("2.6999999946 * 10^10", "2.6999999919000000054 * 10^19"),
    ("2.7999999944 * 10^10", "2.7999999916000000056 * 10^19"),
    ("2.8999999942 * 10^10", "2.8999999913000000058 * 10^19"),
    ("2.9999999940 * 10^10", "2.9999999910000000060 * 10^19"),
    ("3.0999999938 * 10^10", "3.0999999907000000062 * 10^19"),
    ("3.1999999936 * 10^10", "3.1999999904000000064 * 10^19"),
    ("3.2999999934 * 10^10", "3.2999999901000000066 * 10^19"),
    ("3.3999999932 * 10^10", "3.3999999898000000068 * 10^19"),
    ("3.4999999930 * 10^10", "3.4999999895000000070 * 10^19"),
    ("3.5999999928 * 10^10", "3.5999999892000000072 * 10^19"),
    ("3.6999999926 * 10^10", "3.6999999889000000074 * 10^19"),
    ("3.7999999924 * 10^10", "3.7999999886000000076 * 10^19"),
    ("3.8999999922 * 10^10", "3.8999999883000000078 * 10^19"),
    ("3.9999999920 * 10^10", "3.9999999880000000080 * 10^19"),
    ("4.0999999918 * 10^10", "4.0999999877000000082 * 10^19"),
    ("4.1999999916 * 10^10", "4.1999999874000000084 * 10^19"),
]

@testset "mul(bf, u32)" begin
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
    
    for (i, tup) in enumerate(test_cpp_mul_u32_ref)
        x = mul(MiniBf(i), UInt32(WORD_MAX-1))
        z = mul(x, WORD_MAX)

        @testset "mul($i, WORD_MAX-1)" begin
            test_to_string(tup[1], x)
        end
        @testset "mul($i*(WORD_MAX-1), WORD_MAX)" begin
            test_to_string(tup[2], z)
        end
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

const test_cpp_mul_ref = [
    ("123456789.", "246913578."),
    ("246913578.", "740740734."),
    ("370370367.", "1.481481468 * 10^9"),
    ("493827156.", "2.469135780 * 10^9"),
    ("617283945.", "3.703703670 * 10^9"),
    ("740740734.", "5.185185138 * 10^9"),
    ("864197523.", "6.913580184 * 10^9"),
    ("987654312.", "8.888888808 * 10^9"),
    ("1.111111101 * 10^9", "1.1111111010 * 10^10"),
    ("1.234567890 * 10^9", "1.3580246790 * 10^10"),
    ("1.358024679 * 10^9", "1.6296296148 * 10^10"),
    ("1.481481468 * 10^9", "1.9259259084 * 10^10"),
    ("1.604938257 * 10^9", "2.2469135598 * 10^10"),
    ("1.728395046 * 10^9", "2.5925925690 * 10^10"),
    ("1.851851835 * 10^9", "2.9629629360 * 10^10"),
    ("1.975308624 * 10^9", "3.3580246608 * 10^10"),
    ("2.098765413 * 10^9", "3.7777777434 * 10^10"),
    ("2.222222202 * 10^9", "4.2222221838 * 10^10"),
    ("2.345678991 * 10^9", "4.6913579820 * 10^10"),
    ("2.469135780 * 10^9", "5.1851851380 * 10^10"),
    ("2.592592569 * 10^9", "5.7037036518 * 10^10"),
    ("2.716049358 * 10^9", "6.2469135234 * 10^10"),
    ("2.839506147 * 10^9", "6.8148147528 * 10^10"),
]

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
    
    X = MiniBf(123_456_789)
    for (i, tup) in enumerate(test_cpp_mul_ref)
            y = mul(MiniBf(i), X)
            z = mul(y, MiniBf(i+1))

            @testset "mul($i, 123456789)" begin
                test_to_string(tup[1], y)
            end
            @testset "mul($i*123456789, $(i+1))" begin
                test_to_string(tup[2], z)
            end
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

        if i == 1
            continue
        elseif 2 <= i <= 10
            prefix = 2  # "0."
            test_to_string(val[1:11+prefix], rcp(MiniBf(i), zero(UInt64)), 11)
        else
            prefix = 3  # "0.0"
            test_to_string(val[1:11+prefix], rcp(MiniBf(i), zero(UInt64)), 11)
        end
    end
end

"""
[
    string(BigFloat(i)/(i+1)) for i in 1:42
]
"""
const test_cpp_div_ref = String[
    "0.500000000000000000",
    "0.666666666666666624",
    "0.750000000000000000",
    "0.800000000000000000",
    "0.833333333333333280",
    "0.857142857142856992",
    "0.875000000000000000",
    "0.888888888888888832",
    "0.900000000000000000",
    "0.909090909090909120",
    "0.916666666666666608",
    "0.923076923076923136",
    "0.928571428571428408",
    "0.933333333333333296",
    "0.937500000000000000",
    "0.941176470588235264",
    "0.944444444444444384",
    "0.947368421052631632",
    "0.950000000000000000",
    "0.952380952380952320",
    "0.954545454545454576",
    "0.956521739130434752",
    "0.958333333333333272",
    "0.960000000000000000",
    "0.961538461538461600",
    "0.962962962962963040",
    "0.964285714285714116",
    "0.965517241379310256",
    "0.966666666666666628",
    "0.967741935483870960",
    "0.968750000000000000",
    "0.969696969696969728",
    "0.970588235294117616",
    "0.971428571428571448",
    "0.972222222222222160",
    "0.972972972972973008",
    "0.973684210526315844",
    "0.974358974358974320",
    "0.975000000000000000",
    "0.975609756097560960",
    "0.976190476190476128",
    "0.976744186046511624",
]

@testset "div" begin
    @test div(MiniBf(1), MiniBf(1), zero(UInt64)) ==
        MiniBf(true, -1, 0x0000000000000002, UInt32[0x00000000, 0x00000001, 0x00000000]) 

    for (i, val) in enumerate(test_cpp_div_ref)
        test_to_string(val, div(MiniBf(i), MiniBf(i+1), zero(UInt64)))
        test_to_string(val[1:11+2], div(MiniBf(i), MiniBf(i+1), zero(UInt64)), 11)
    end

    @testset "rcp(MiniBf(113), UInt64(1))" begin
        to_digits = 41
        p = UInt64(1)
        x = MiniBf(113)
        r0 = rcp(MiniBf(113), zero(UInt64))
        @test "0.008849557522123894" == to_string(r0, to_digits)
        r0x = mul(r0, x, p)
        @test "1.000000000000000022" == to_string(r0x, to_digits)
        sub1 = sub(r0x, MiniBf(1), UInt64(1))
        @test "2.2 * 10^-17" == to_string(sub1, to_digits)
        mulr0 = mul(sub1, r0, p)
        @test "1.94690265486725668 * 10^-19" == to_string(mulr0, to_digits)
        r1 = sub(r0, mulr0, p)
        @test "0.008849557522123893805309735" == to_string(r1, to_digits)
    end

    to_digits = 40
    to_digits += 1
    p = (to_digits + 8) / 9
    p = trunc(UInt64, p)

    @test "0.008849557522123893805309735" ==
        to_string(rcp(MiniBf(113), UInt64(1)), to_digits)
    @test "0.008849557522123893805309734513274337" ==
        to_string(rcp(MiniBf(113), UInt64(2)), to_digits)
    @test "0.0088495575221238938053097345132743362831858" ==
        to_string(rcp(MiniBf(113), UInt64(3)), to_digits)
    @test "0.0088495575221238938053097345132743362831858" ==
        to_string(rcp(MiniBf(113), p), to_digits)

    @test "3.1415929203539823008849557522123893805309" ==
        to_string(div(MiniBf(355), MiniBf(113), p), to_digits)
end
