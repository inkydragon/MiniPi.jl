import MiniPi: pi_bsr, Pi


function gen_dpt(to_digits)
    to_digits += 1

    p = (to_digits + 8) / 9
    p = trunc(UInt64, p)

    terms = (p * 0.6346230241342037371474889163921741077188431452678) + 1
    terms = trunc(UInt32, terms)

    to_digits, p, terms
end

@testset "pi_bsr" begin
    P, Q, R = pi_bsr(UInt32(0), UInt32(1), UInt64(3))
    test_to_string("-2.793657715 * 10^9", P)
    test_to_string("1.0939058860032000 * 10^16", Q)
    test_to_string("5.", R)

    P, Q, R = pi_bsr(UInt32(1), UInt32(2), UInt64(3))
    test_to_string("2.54994357387 * 10^11", P)
    test_to_string("8.7512470880256000 * 10^16", Q)
    test_to_string("231.", R)

    P, Q, R = pi_bsr(UInt32(0), UInt32(2), UInt64(3))
    test_to_string("-2.44479889433338740603253065 * 10^26", P)
    test_to_string("9.57304069945956794936328192000000 * 10^32", Q)
    test_to_string("1155.", R)

    to_digits, p, terms = gen_dpt(20)
    P, Q, R = pi_bsr(UInt32(0), terms, p)
    test_to_string("-2.44479889433338740603253065 * 10^26", P, to_digits)
    test_to_string("9.57304069945956794936328192000000 * 10^32", Q, to_digits)
    test_to_string("1155.", R, to_digits)

    to_digits, p, terms = gen_dpt(50)
    P, Q, R = pi_bsr(UInt32(0), terms, p)
    test_to_string(
        "-5.0552984125686101746228994534091499889077848307882335805887375 * 10^61",
        P, to_digits)
    test_to_string(
        "1.97949113784380161370086287723699183824180409892941594624000000000000 * 10^68",
        Q, to_digits)
    test_to_string("3.904125225 * 10^9", R, to_digits)
end


# Pi Reference data
include("pi_ref.jl")

@testset "Pi" begin
    @test_throws DomainError Pi(61*10^9)

    to_digits, p, terms = gen_dpt(50)
    @test pi_50 == to_string(Pi(to_digits), to_digits)

    to_digits, p, terms = gen_dpt(100)
    @test pi_100 == to_string(Pi(to_digits), to_digits)
end
