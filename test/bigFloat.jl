import MiniPi
import MiniPi:
    EXTRA_PRECISION, WORD_SIZE, WORD_MAX,
    MiniBf,
    precision, exponent, word_at,
    ucmp,
    # String Conversion
    to_string_trimmed!, to_string_sci!, to_string,
    negate!, mul


@testset "const" begin
    @test 2 == EXTRA_PRECISION
    @test 10^9 == WORD_SIZE
    @test WORD_SIZE == (WORD_MAX + 1)
end

@testset "help functions" begin
    @test isnothing(MiniPi.check_word_size(0))
    @test isnothing(MiniPi.check_word_size(WORD_MAX))
    @test_throws DomainError MiniPi.check_word_size(WORD_SIZE)
    
    @test 0 == MiniPi._magnitude(MiniBf())
    @test 1 == MiniPi._magnitude(MiniBf(42))
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
    @test MiniBf(1) != MiniBf()
    @test MiniBf(10) != MiniBf(1)
    @test MiniBf(10) != mul(MiniBf(WORD_MAX), MiniBf(100))

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
    
    # Base
    @test MiniBf(0) == zero(MiniBf)
    @test MiniBf(1) == one(MiniBf)
end

@testset "Base.precision" begin
    @test precision(MiniBf()) == 0
    @test precision(MiniBf(UInt32(1))) == 1
end

@testset "Base.exponent" begin
    @test exponent(MiniBf()) == 0
    @test exponent(MiniBf(UInt32(1))) == 0
end

@testset "word_at" begin
    bf0 = MiniBf()
    @test 0 == word_at(bf0, -1)
    @test 0 == word_at(bf0, 0)
    @test 0 == word_at(bf0, 1)

    bfx = MiniBf(47)
    @test 0 == word_at(bfx, -1)
    @test 47 == word_at(bfx, 0)
    @test 0 == word_at(bfx, 1)

    # TODO: test exp != 0;  len > 1
end

function ucmp_gt(x, y)
    @test MiniPi.BF_LARGER == ucmp(MiniBf(x), MiniBf(y))
    @test MiniPi.BF_LARGER == ucmp(MiniBf(x), MiniBf(-y))
    @test MiniPi.BF_LARGER == ucmp(MiniBf(-x), MiniBf(y))
    @test MiniPi.BF_LARGER == ucmp(MiniBf(-x), MiniBf(-y))
end

function ucmp_eq(x, y)
    @test MiniPi.BF_EQUAL == ucmp(MiniBf(x), MiniBf(y))
    @test MiniPi.BF_EQUAL == ucmp(MiniBf(x), MiniBf(-y))
    @test MiniPi.BF_EQUAL == ucmp(MiniBf(-x), MiniBf(y))
    @test MiniPi.BF_EQUAL == ucmp(MiniBf(-x), MiniBf(-y))
end

function ucmp_lt(x, y)
    @test MiniPi.BF_SMALLER == ucmp(MiniBf(x), MiniBf(y))
    @test MiniPi.BF_SMALLER == ucmp(MiniBf(x), MiniBf(-y))
    @test MiniPi.BF_SMALLER == ucmp(MiniBf(-x), MiniBf(y))
    @test MiniPi.BF_SMALLER == ucmp(MiniBf(-x), MiniBf(-y))
end

@testset "ucmp" begin
    # gt >
    @test MiniPi.BF_LARGER == ucmp(MiniBf(1), MiniBf(0))
    ucmp_gt(1, 0)
    for i in 1:10
        ucmp_gt(i, 0)
        ucmp_gt(i+1, i)
    end

    y = div(MiniBf(1), MiniBf(1_00_000_000), UInt64(0))
    @test MiniPi.BF_LARGER == ucmp(MiniBf(1), MiniBf(y))

    # eq ==
    @test MiniPi.BF_EQUAL == ucmp(MiniBf(), MiniBf())
    @test MiniPi.BF_EQUAL == ucmp(MiniBf(0), MiniBf())
    @test MiniPi.BF_EQUAL == ucmp(MiniBf(1), MiniBf(1))
    ucmp_eq(0, 0)
    ucmp_eq(1, 1)

    # lt <
    @test MiniPi.BF_SMALLER == ucmp(MiniBf(), MiniBf(1))
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
    function test_to_string_sci(ref, x, to_digits=0)
        u8 = zeros(UInt8, to_digits)

        @test ref == to_string_sci!(u8, x, to_digits)
        x == MiniBf(0) && return

        @test "-" * ref == to_string_sci!(u8, negate!(x), to_digits)
    end

    test_to_string_sci("0.", MiniBf(0))
    test_to_string_sci("1.", MiniBf(1))
    test_to_string_sci("2.", MiniBf(2))
    test_to_string_sci("9.99999998 * 10^8", MiniBf(WORD_MAX-1))
    test_to_string_sci("9.99999999 * 10^8", MiniBf(WORD_MAX))

    test_to_string_sci("9.999999990 * 10^9", mul(MiniBf(WORD_MAX), MiniBf(10)))
    test_to_string_sci("9.9999999900 * 10^10", mul(MiniBf(WORD_MAX), MiniBf(100)))
    test_to_string_sci("9.99999998000000001 * 10^17", mul(MiniBf(WORD_MAX), MiniBf(WORD_MAX)))
end

function test_to_string(ref, x, to_digits=0)
    @test ref == to_string(x, to_digits)
    x == MiniBf(0) && return

    if startswith(ref, "-")
        @test ref[2:end] == to_string(negate!(x), to_digits)
    else
        @test "-" * ref == to_string(negate!(x), to_digits)
    end
end

@testset "to_string" begin
    test_to_string("0.", MiniBf(0))
    test_to_string("1.", MiniBf(1))
    test_to_string("2.", MiniBf(2))
    test_to_string("999999998.", MiniBf(WORD_MAX-1))
    test_to_string("999999999.", MiniBf(WORD_MAX))
    test_to_string("9.999999990 * 10^9", mul(MiniBf(WORD_MAX), MiniBf(10)))
    test_to_string("9.9999999900 * 10^10", mul(MiniBf(WORD_MAX), MiniBf(100)))
    test_to_string("9.99999998000000001 * 10^17", mul(MiniBf(WORD_MAX), MiniBf(WORD_MAX)))

    # < 1
    test_to_string("0.100000000000000000", div(MiniBf(1), MiniBf(10), zero(UInt64)))
    test_to_string("0.000001000000000000", div(MiniBf(1), MiniBf(1000_000), zero(UInt64)))
    test_to_string("0.000000001000000001", div(MiniBf(1), MiniBf(WORD_MAX), zero(UInt64)))
    test_to_string("0.000000001000000001", div(MiniBf(1), MiniBf(WORD_MAX), zero(UInt64)))

    # pi
    test_to_string("3.142857142857142304", div(MiniBf(22), MiniBf(7), zero(UInt64)))
    test_to_string("3.141592920353982370", div(MiniBf(355), MiniBf(113), zero(UInt64)))
end

@testset "to_string(to_digits)" begin
    p = zero(UInt64)
    test_to_string("1.00000000000000000000 * 10^-16", 
        div(div(MiniBf(1), MiniBf(1_00_000_000), p), MiniBf(1_00_000_000), p), 0)

    # digits
    test_to_string("3.14159", div(MiniBf(355), MiniBf(113), zero(UInt64)), 5+1)
    test_to_string("3.1415929203", div(MiniBf(355), MiniBf(113), zero(UInt64)), 10+1)
    test_to_string("3.141592920353982370", div(MiniBf(355), MiniBf(113), zero(UInt64)), 20+1)
    test_to_string("3.141592920353982370", div(MiniBf(355), MiniBf(113), zero(UInt64)), 40+1)
end
