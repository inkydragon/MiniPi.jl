"""
Math functions for MiniBigFloat
"""

#= Arithmetic =#

"""
    negate!(x::MiniBf)

Negate this number.
"""
function negate!(x::MiniBf)
    if x.len != 0
        x.sign = !x.sign
    end

    x
end

"""
    mul(x::MiniBf, y::UInt32)

Multiply by a 32-bit unsigned integer.
"""
function mul(x::MiniBf, y::UInt32)
    z = MiniBf()
    if iszero(x.len) || iszero(y)
        # 0
        return z
    end

    # Compute basic fields.
    z.sign = x.sign
    z.exp  = x.exp
    z.len  = x.len

    # Allocate mantissa
    z.tab = zeros(UInt32, z.len + 1)

    carry = zero(UInt64)
    for c in one(UInt64):(x.len)
        # Multiply and add to carry
        # NOTE: Must be calculated with UInt 
        carry += UInt64(x.tab[c]) * UInt64(y)
        # Store bottom 9 digits
        z.tab[c] = UInt32(carry % WORD_SIZE)
        # Shift down the carry
        carry = div(carry, WORD_SIZE)
    end

    # Carry out
    if carry != 0
        z.len += 1
        z.tab[z.len] = UInt32(carry)
    end

    z
end
mul(x::MiniBf, y::Unsigned) = mul(x, UInt32(y))

"""
    uadd(x::MiniBf, y::MiniBf, p=zero(UInt64))

Perform addition ignoring the sign of the two operands.
"""
function uadd(x::MiniBf, y::MiniBf, p=zero(UInt64))
    # Magnitude
    magA = x.exp + Int64(x.len)
    magB = y.exp + Int64(y.len)
    top = max(magA, magB)
    bot = min(x.exp, y.exp)

    # Target length
    TL = top - bot

    if iszero(p)
        # Default value. No truncation.
        p = UInt64(TL)
    else
        # Increase precision
        p += EXTRA_PRECISION
    end

    # Perform precision truncation.
    if TL > Int(p)
        bot = top - p
        TL = p
    end

    # Compute basic fields.
    z = MiniBf()
    z.sign = x.sign
    z.exp = bot
    z.len = TL

    # Allocate mantissa
    z.tab = zeros(UInt32, z.len + 1)

    # Add
    carry = 0
    c = one(UInt64)
    for bot in bot:(top-1)
        word = word_at(x, bot) + word_at(y, bot) + carry
        carry = 0
        if word >= WORD_SIZE
            word -= WORD_SIZE
            carry = 1
        end
        z.tab[c] = word
        c += 1
    end

    # Carry out
    if carry != 0
        z.len += 1
        z.tab[z.len] = 1
    end

    return z
end

"""
    usub(xx::MiniBf, yy::MiniBf, p=zero(UInt64))

Perform subtraction ignoring the sign of the two operands.

"this" must be greater than or equal to y. Otherwise, the behavior
is undefined.
"""
function usub(x::MiniBf, y::MiniBf, p=zero(UInt64))
    # @assert x >= y

    # Magnitude
    magA = x.exp + Int64(x.len)
    magB = y.exp + Int64(y.len)
    top = max(magA, magB)
    bot = min(x.exp, y.exp)

    # Truncate precision
    TL = top - bot

    if iszero(p)
        # Default value. No trunction.
        p = UInt64(TL)
    else
        # Increase precision
        p += EXTRA_PRECISION
    end

    if TL > Int(p)
        bot = top - Int(p)
        TL = p
    end

    # Compute basic fields.
    z = MiniBf()
    z.sign = x.sign
    z.exp = bot
    z.len = TL

    # Allocate mantissa
    z.tab = zeros(UInt32, z.len)

    # Subtract
    carry = 0
    c = one(UInt64)
    for bot in bot:(top-1)
        word = word_at(x, bot) - word_at(y, bot) - carry
        carry = 0
        if word < 0
            word += WORD_SIZE
            carry = 1
        end
        z.tab[c] = word
        c += 1
    end

    # Strip leading zeros
    while z.len > 0 && iszero(z.tab[z.len])
        z.len -= 1
    end

    if iszero(z.len)
        z.exp = 0
        z.sign = true
        z.tab = zeros(UInt32, 0)
    end

    return z
end

"""
    add(x::MiniBf, y::MiniBf, p=zero(UInt64))

Addition

The target precision is p.

If (p = 0), then no truncation is done. The entire operation is done
at maximum precision with no data loss.
"""
function add(x::MiniBf, y::MiniBf, p=zero(UInt64))
    if x.sign == y.sign
        # Same sign. Add.
        uadd(x, y, p)
    elseif ucmp(x, y) > 0
        # x >= 0 > y
        usub(x, y, p)
    else
        # y >= 0 > x
        usub(y, x, p)
    end
end

"""
    sub(x::MiniBf, y::MiniBf, p=zero(UInt64))

Subtraction: x - y, 
The target precision is p.

If (p = 0), then no truncation is done.
The entire operation is done at maximum precision with no data loss.
"""
function sub(x::MiniBf, y::MiniBf, p=zero(UInt64))
    if x.sign != y.sign
        # Different sign. Add.
        uadd(x, y, p)
    elseif ucmp(x, y) > 0
        # x > y
        usub(x, y, p)
    else
        # y > x
        z = usub(y, x, p)
        negate!(z)
    end
end

"""
    mul(x::MiniBf, y::MiniBf, p=zero(UInt64))

Multiplication

The target precision is p.
If (p = 0), then no truncation is done. The entire operation is done
at maximum precision with no data loss.

Depend on: [`multiply_fft!`](@ref)
"""
function mul(x::MiniBf, y::MiniBf, p=zero(UInt64))
    # Either operand is zero.
    if iszero(x.len) || iszero(y.len)
        return MiniBf()
    end

    if iszero(p)
        # Default value. No truncation.
        p = x.len + y.len
    else
        # Increase precision
        p += EXTRA_PRECISION
    end

    # Collect operands.
    Aexp = x.exp
    Bexp = y.exp
    AL = x.len
    BL = y.len
    AT = x.tab
    BT = y.tab

    # Perform precision truncation.
    idx_A = 0
    if AL > p
        chop = AL - p
        AL = p
        Aexp += chop
        idx_A = chop
    end
    
    idx_B = 0
    if BL > p
        chop = BL - p
        BL = p
        Bexp += chop
        idx_B = chop
    end

    # Compute basic fields.
    z = MiniBf()
    z.sign = x.sign == y.sign   # Sign is positive if signs are equal.
    z.exp = Aexp + Bexp         # Add the exponents.
    z.len = AL + BL             # Add the length for now. May need to correct later.

    # Allocate mantissa
    z.tab = zeros(UInt32, z.len)

    # Perform multiplication using FFT.
    # TODO: use @view
    view_A = AT[(idx_A+1):end]
    view_B = BT[(idx_B+1):end]
    multiply_fft!(z.tab, view_A, AL, view_B, BL)

    # Check top word and correct length.
    if iszero(z.tab[z.len])
        z.len -= 1
    end

    z
end

"""
    rcp(x::MiniBf, p::UInt64)

Compute reciprocal using Newton's Method.

    r1 = r0 - (r0 * x - 1) * r0

Depend on: rcp, sub, mul
"""
function rcp(x::MiniBf, p::UInt64)
    if iszero(x.len)
        throw(DomainError("Divide by Zero."))
    end

    # Collect operand
    Aexp = x.exp
    AL = x.len

    # End of recursion. Generate starting point.
    if iszero(p)
        # Truncate precision to 3.
        idx_x = 0
        p = 3
        if AL > p
            chop = AL - p
            AL = p
            Aexp += chop
            idx_x = chop
        end

        # Convert number to floating-point.
        val = x.tab[idx_x+1]
        if AL >= 2
            val += x.tab[idx_x+2] * WORD_SIZE
        end
        if AL >= 3
            val += x.tab[idx_x+3] * WORD_SIZE * WORD_SIZE
        end

        # Compute reciprocal.
        val = 1.0 / val
        Aexp = -Aexp

        # Scale
        while val < WORD_SIZE
            val *= WORD_SIZE
            Aexp -= 1
        end

        # Rebuild a MiniBf.
        val64 = trunc(UInt64, val)

        out = MiniBf()
        out.sign = x.sign

        out.tab = UInt32[val64 % WORD_SIZE, val64 ÷ WORD_SIZE]
        out.len = 2
        out.exp = Aexp

        return out
    end

    # Half the precision
    s = div(p, 2) + 1
    if p == 1
        s = UInt64(0)
    end
    if p == 2
        s = UInt64(1)
    end

    # Recurse at half the precision
    r0 = rcp(x, s)

    # r1 = r0 - (r0 * x - 1) * r0
    r0x = mul(r0, x, p)
    sub1 = sub(r0x, MiniBf(1), p)
    mulr0 = mul(sub1, r0, p)
    r1 = sub(r0, mulr0, p)

    return r1
end

"""
    Base.div(x::MiniBf, y::UInt32, p::UInt64)

Division

Depend on: mul, rcp
"""
function Base.div(x::MiniBf, y::MiniBf, p::UInt64)
    inv_y = rcp(y, p)
    mul(x, inv_y, p)
end

"""
Depend on: invsqrt, sub, mul
"""
function invsqrt(x::MiniBf, y::UInt32, p) end
