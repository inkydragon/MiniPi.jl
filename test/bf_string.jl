# SPDX-License-Identifier: MIT
#= String Conversion =#
import MiniPi: to_string_trimmed!, to_string_sci!, to_string,
    negate!


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
