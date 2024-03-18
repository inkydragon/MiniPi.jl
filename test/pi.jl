import MiniPi: pi_bsr, Pi


@testset "pi_bsr" begin
    to_digits = 50
    to_digits += 1

    p = (to_digits + 8) / 9
    p = trunc(UInt64, p)
    terms = (p * 0.6346230241342037371474889163921741077188431452678) + 1
    terms = trunc(UInt32, terms)
    P, Q, R = pi_bsr(UInt32(0), terms, p)

    test_to_string("-5.0552984125686101746228994534091499889077848307882335805887375 * 10^61", P, to_digits)
    test_to_string("1.97949113784380161370086287723699183824180409892941594624000000000000 * 10^68", Q, to_digits)
    test_to_string("3.904125225 * 10^9", R, to_digits)
end
