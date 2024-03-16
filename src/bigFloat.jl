
"Precision increase step."
const EXTRA_PRECISION = UInt64(2)
"Word size = 10^9"
const WORD_SIZE = UInt32(1_000_000_000)
"Word max"
const WORD_MAX = UInt32(1_000_000_000 - 1)

function check_word_size(x)
    if x >= WORD_SIZE
        throw(DomainError("x too large. Only impl MiniBf() for x < WORD_SIZE($WORD_SIZE)"))
    end
end


#= Constructors =#
"""
The Big Floating-point object.
It represents an arbitrary precision floating-point number.


Its numerical value is equal to:
```
    word = 10^9
    word^exp * (T[0] + T[1]*word + T[2]*word^2 + ... + T[L - 1]*word^(L - 1))
```

T is an array of 32-bit integers. Each integer stores 9 decimal digits
and must always have a value in the range `[0, 999999999]`.

`T[L - 1]` must never be zero. 

The number is positive when (sign = true) and negative when (sign = false).
Zero is represented as (sign = true) and (len = 0).
"""
mutable struct MiniBf <: AbstractFloat
    "true = positive or zero; false = negative"
    sign::Bool
    "Exponent"
    exp::Int64
    "Length"
    len::UInt64
    
    tab::Vector{UInt32}
end

function MiniBf()
    MiniBf(true, zero(Int64), zero(UInt64), UInt32[])
end
MiniBf(bf::MiniBf) = bf

"""
    MiniBf(x::UInt32, sign=true)

Construct a BigFloat with a value of x and the specified sign.
"""
function MiniBf(x::UInt32, sign=true)
    bf = MiniBf(true, zero(Int64), one(UInt64), UInt32[])

    if iszero(x)
        bf.len = 0
    else
        check_word_size(x)
        bf.sign = sign
        bf.tab = UInt32[x]
    end

    @assert length(bf.tab) == bf.len
    bf
end

function MiniBf(x::Integer)
    abs_x = Base.Checked.checked_abs(x)
    check_word_size(x)

    MiniBf(UInt32(abs_x), !signbit(x))
end


#= String Conversion =#
function to_string_trimmed(x::MiniBf, digits) end
function to_string(bf::MiniBf, digits=0) end
function to_string_sci(bf::MiniBf, digits=0) end


#= Getter =#
"""
    Base.precision(x::MiniBf)

Returns the precision of the number in words.

Note that each word is 9 decimal digits.
"""
function Base.precision(x::MiniBf)
    x.len
end

"""
    Base.exponent(x::MiniBf)
    
Returns the exponent of the number in words.

Note that each word is 9 decimal digits.
"""
function Base.exponent(x::MiniBf)
    x.exp
end

"""
    word_at(x::MiniBf, mag::Int64)

Returns the word at the mag'th digit place.

This is useful for additions where you need to access a specific "digit place"
of the operand without having to worry if it's out-of-bounds.

This function is mathematically equal to:
```
(return value) = floor(this * (10^9)^-mag) % 10^9
```

TODO: use getindex
"""
function word_at(x::MiniBf, mag::Int64)
    if mag < x.exp || mag >= (x.exp+x.len)
        return 0
    end

    return x.tab[Int(mag - x.exp) + 1]
end


#= Compare Ops =#

function Base.:(==)(x::MiniBf, y::MiniBf)
    # TODO: use normalize

    if iszero(x.len) || iszero(y.len)
        # skip compare .tab[]
        x.len == y.len &&
            x.sign == y.sign &&
            x.exp == y.exp
    elseif x.len == y.len
        @assert length(x.tab) >= x.len
        @assert length(y.tab) >= y.len

        x.sign == y.sign &&
            x.exp == y.exp &&
            x.len == y.len &&
            # NOTE: x.tab may contains extra 0x0 at end
            x.tab[1:x.len] == y.tab[1:y.len]
    else
        false
    end
end

"""
    ucmp(x::MiniBf, y::MiniBf)

Compare function that ignores the sign.

This is needed to determine which direction subtractions will go.
"""
function ucmp(x::MiniBf, y::MiniBf)
    magA = x.exp + x.len
    magB = y.exp + y.len
    
    if magA > magB
        return 1
    elseif magA < magB
        return -1
    end

    mag = Int(magA)
    while mag >= x.exp || mag >= y.exp
        wordA = word_at(x, mag)
        wordB = word_at(y, mag)
        if wordA < wordB
            return -1
        elseif wordA > wordB
            return 1
        end

        mag -= 1
    end
    
    return 0
end


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
        carry += x.tab[c] * y
        # Store bottom 9 digits
        z.tab[c] = carry % WORD_SIZE
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

    if p == 0
        # Default value. No truncation.
        p = TL
    else
        # Increase precision
        p += EXTRA_PRECISION
    end

    # Perform precision truncation.
    if TL > p
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

    if p == 0
        # Default value. No trunction.
        p = TL
    else
        # Increase precision
        p += EXTRA_PRECISION
    end

    if TL > p
        bot = top - p
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
    if x.len == 0 || y.len == 0
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
Depend on: rcp, sub, mul
"""
function rcp(x::MiniBf, p) end

"""
Depend on: mul, rcp
"""
function Base.div(x::MiniBf, y::UInt32, p) end

"""
Depend on: invsqrt, sub, mul
"""
function invsqrt(x::MiniBf, y::UInt32, p) end
