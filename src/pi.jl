
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

    tmp = mul(P0, Q1, p)
    temp = mul(P1, R0, p)
    P = add(tmp, temp, p)
    @show to_string(tmp) to_string(temp) to_string(P) 
    Q = mul(Q0, Q1, p)
    R = mul(R0, R1, p)

    return P, Q, R
end


"""
Compute Pi using the Chudnovsky Formula.
"""
function Pi(to_digits::Int64, write_to_file=false)
    # The leading 3 doesn't count.
    to_digits += 1

    p = (to_digits + 8) / 9
    p = trunc(UInt64, p)
    terms = (p * 0.6346230241342037371474889163921741077188431452678) + 1
    terms = trunc(UInt64, terms)

    if terms > typemax(UInt32)
        throw(DomainError("Limit Exceeded"))
    end
    terms = UInt32(terms)

    ensure_fft_tables(2*p)

    ns0 = time_ns()
    @info "Computing Pi..."
    @info "Algorithm: Chudnovsky Formula\n"

    @info "Summing Series... $(Int(terms)) terms"
    P, Q, R = MiniBf(), MiniBf(), MiniBf()
    @time begin
        P, Q, R = pi_bsr(UInt32(0), terms, p)
        P = add(mul(Q, UInt32(13591409)), P, p)
        Q = mul(Q, UInt32(4270934400))
    end

    @info "Division..."
    @time begin
        P = div(Q, P, p)
    end

    @info "InvSqrt..."
    @time begin
        Q = invsqrt(UInt32(10005), p)
    end

    @info "Final Multiply..."
    @time begin
        P = mul(P, Q, p)
    end
    ns1 = time_ns()
    
    time_in_s = (ns1 - ns0) / 1e9
    @info "Total Time = $time_in_s s"

    if write_to_file
        open("pi.txt", "w") do file
            write(file, to_string(P, to_digits))
        end
    end

    P
end
