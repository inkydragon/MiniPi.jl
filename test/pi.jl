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
    to_digits, p, terms = gen_dpt(20)
    P, Q, R = pi_bsr(UInt32(0), terms, p)
    test_to_string("-2.44479889433338740603253065 * 10^26", P, to_digits)
    test_to_string("9.57304069945956794936328192000000 * 10^32", Q, to_digits)
    test_to_string("1155.", R, to_digits)
end
