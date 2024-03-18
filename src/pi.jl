
"""
Binary Splitting recursion for the Chudnovsky Formula.
"""
function pi_bsr(a::UInt32, b::UInt32, p::UInt64)
    if b - a == 1
        # P = (13591409 + 545140134*b)(2b-1)(6b-5)(6b-1) (-1)^b
        P = mul(MiniBf(b), UInt32(545140134))
        P = add(P, MiniBf(13591409))
        P = mul(P, UInt32(2*b - 1))
        P = mul(P, UInt32(6*b - 5))
        P = mul(P, UInt32(6*b - 1))
        if b % 2 == 1
            negate!(P)
        end

        # Q = 10939058860032000 * b^3
        b3 = MiniBf(b)
        Q = mul(b3, b3)
        Q = mul(Q, b3)
        Q = mul(Q, UInt32(26726400))
        Q = mul(Q, UInt32(409297880))

        # R = (2b-1)(6b-5)(6b-1)
        R = MiniBf(2*b - 1)
        R = mul(R, UInt32(6*b - 5))
        R = mul(R, UInt32(6*b - 1))

        return P, Q, R
    end

    m = div(a+b, UInt32(2))

    P0, Q0, R0 = pi_bsr(a, m, p)
    P1, Q1, R1 = pi_bsr(m, b, p)

    P = mul(P0, Q1, p)
    P = add(P, mul(P1, R0, p), p)
    Q = mul(Q0, Q1, p)
    R = mul(R0, R1, p)

    return P, Q, R
end
