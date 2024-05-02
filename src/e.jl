
"""(log(2*pi) + 1) / 2"""
const log2pi_p1d2 = Float64((log(2*BigFloat(pi)) + 1) / 2)


"""
    logf_approx(x::Float64)

Returns a very good approximation to `log(x!)`.

```
log(x!) ~ (x + 1/2) * (log(x) - 1) + (log(2*pi) + 1) / 2
```

This approximation gets better as `x` is larger.
"""
function logf_approx(x::Float64)
    if x <= 1.0
        return 0.0
    end

    return (x + 0.5) * (log(x) - 1.0) + log2pi_p1d2
end

"""
Returns the # of terms needed to reach a precision of `p`.

The taylor series converges to `log(x!) / log(10)` decimal digits after
`x` terms. So to find the number of terms needed to reach a precision of `p`
we need to solve this question for `x`:
```
p = log(x!) / log(1_000_000_000)
```

This function solves this equation via binary search.
"""
function e_terms(p::UInt64)
    sizeL = float(p) * 20.723265836946411156161923092159277868409913397659 + 1
    a = UInt64(0)
    b = UInt64(1)

    # Double up
    while logf_approx(float(b)) < sizeL
        b <<= 1
    end

    # Binary search
    while (b - a) > 1
        m = (a + b) >> 1
        
        if logf_approx(float(m)) < sizeL
            a = m
        else
            b = m
        end
    end

    return b + 2
end

"""
Binary Splitting recursion for exp(1).
"""
function e_bsr(a::UInt32, b::UInt32)
    if (b - a) == 1
        P = MiniBf(1)
        Q = MiniBf(b)
        return P, Q
    end

    m::UInt32 = div(a+b, UInt32(2))

    P0, Q0 = e_bsr(a, m)
    P1, Q1 = e_bsr(m, b)

    P = add(mul(P0, Q1), P1)
    Q = mul(Q0, Q1)

    return P, Q
end


"""
Compute e using the Taylor Series of exp(1).
"""
function Exp(to_digits::Int64, write_to_file=false)
    # The leading 2 doesn't count.
    to_digits += 1

    p = (to_digits + 8) / 9
    p = trunc(UInt64, p)
    terms = e_terms(p)

    if terms > typemax(UInt32)
        throw(DomainError("Limit Exceeded"))
    end
    terms = UInt32(terms)

    ensure_fft_tables(2*p)

    ns0 = time_ns()
    @info "Computing Exp($(float(to_digits-1)) + 1) digits..."
    @info "Algorithm: Taylor Series of exp(1)a\n"

    @info "Summing Series... $(Int(terms)) terms"
    P, Q = MiniBf(), MiniBf()
    @time begin
        P, Q = e_bsr(UInt32(0), terms)
    end

    @info "Division..."
    @time begin
        P = div(P, Q, p)
        P = add(P, MiniBf(1), p)
    end
    ns1 = time_ns()

    time_in_s = (ns1 - ns0) / 1e9
    @info "Total Time = $time_in_s s"
    println("")  # add newline at end

    if write_to_file
        open("e.txt", "w") do file
            write(file, to_string(P, to_digits))
        end
    end

    P
end
