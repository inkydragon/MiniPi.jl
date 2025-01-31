# SPDX-License-Identifier: MIT
# Based on Mysticial/Mini-Pi/decomposed/src/BigFloat.cpp
#   Author: Alexander J. Yee, CC0-1.0 License
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
    magA = _magnitude(x)
    magB = _magnitude(y)
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
        bot = top - Int(p)
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
    magA = _magnitude(x)
    magB = _magnitude(y)
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
        word = Int(word_at(x, bot)) - Int(word_at(y, bot)) - carry
        carry = 0
        if word < 0
            word += Int(WORD_SIZE)
            carry = 1
        end
        z.tab[c] = trunc(UInt32, word)
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
        # y >= x
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
        Aexp += Int(chop)
        idx_A = chop
    end

    idx_B = 0
    if BL > p
        chop = BL - p
        BL = p
        Bexp += Int(chop)
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

function _rcp(x::MiniBf)
    @assert x.len > 0 "Divide by Zero."
    WORD_SIZE_F64 = Float64(WORD_SIZE)

    # Collect operand
    Aexp = x.exp
    AL = x.len

    # Truncate precision to 3.
    p = UInt64(3)
    idx_x = 0
    if AL > p
        chop = AL - p
        AL = p
        Aexp += Int(chop)
        idx_x = chop
    end

    # Convert number to floating-point.
    val = Float64(x.tab[idx_x+1])
    if AL >= 2
        val += x.tab[idx_x+2] * WORD_SIZE_F64
    end
    if AL >= 3
        val += x.tab[idx_x+3] * WORD_SIZE_F64 * WORD_SIZE_F64
    end

    # Compute reciprocal.
    val = 1.0 / val
    Aexp = -Aexp

    # Scale
    while val < WORD_SIZE_F64
        val *= WORD_SIZE_F64
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

function _rcp_kernel_rec(x::MiniBf, p::UInt64)
    @assert x.len > 0 "Divide by Zero."

    # End of recursion. Generate starting point.
    if iszero(p)
        return _rcp(x)
    end

    # Half the precision
    s = div(p, 2) + UInt64(1)
    if p == 1
        s = UInt64(0)
    end
    if p == 2
        s = UInt64(1)
    end

    # Recurse at half the precision
    r0 = _rcp_kernel_rec(x, s)

    # r1 = r0 - (r0 * x - 1) * r0
    r0x = mul(r0, x, p)
    sub1 = sub(r0x, MiniBf(1), p)
    mulr0 = mul(sub1, r0, p)
    r1 = sub(r0, mulr0, p)

    return r1
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

    return _rcp_kernel_rec(x, p)
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
    invsqrt(x::UInt32, p::UInt64)

Compute inverse square root using Newton's Method.

```
            (  r0^2 * x - 1  )
  r1 = r0 - (----------------) * r0
            (       2        )
```

Depend on: invsqrt, sub, mul
"""
function invsqrt(x::UInt32, p::UInt64)
    if iszero(x)
        throw(DomainError("Divide by Zero."))
    end

    # End of recursion. Generate starting point.
    if iszero(p)
        val = 1.0 / sqrt(Float64(x))

        expo = 0

        # Scale
        while val < Float64(WORD_SIZE)
            val *= Float64(WORD_SIZE)
            expo -= 1
        end

        # Rebuild a BigFloat.
        val64 = trunc(UInt64, val)

        out = MiniBf()
        out.sign = true
        out.exp = expo
        out.len = 2
        out.tab = UInt32[val64 % WORD_SIZE, val64 ÷ WORD_SIZE]

        return out
    end

    # Half the precision
    s = div(p, 2) + UInt64(1)
    if p == 1
        s = UInt64(0)
    elseif p == 2
        s = UInt64(1)
    end

    # Recurse at half the precision
    T = invsqrt(x, s)

    temp = mul(T, T, p)             # r0^2
    temp = mul(temp, x)             # r0^2 * x
    temp = sub(temp, MiniBf(1), p)  # r0^2 * x - 1
    HALF_WORD = UInt32(WORD_SIZE/2)
    temp = mul(temp, HALF_WORD)     # (r0^2 * x - 1) / 2
    temp.exp -= 1
    temp = mul(temp, T, p)          # (r0^2 * x - 1) / 2 * r0
    temp = sub(T, temp, p)          # r0 - (r0^2 * x - 1) / 2 * r0

    return temp       
end
