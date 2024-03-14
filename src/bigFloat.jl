
"Precision increase step."
const EXTRA_PRECISION = UInt64(2)
"Word size = 10^9"
const WORD_SIZE = 1_000_000_000

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
        bf.sign = sign
        bf.tab = UInt32[x]
    end

    @assert length(bf.tab) == bf.len
    bf
end
MiniBf(x::Integer) = MiniBf(UInt32(Base.Checked.checked_abs(x)), !signbit(x))

Base.:(==)(x::MiniBf, y::MiniBf) =
    x.sign == y.sign &&
    x.exp == y.exp &&
    x.len == y.len &&
    x.tab == y.tab


function to_string(bf::MiniBf, digits=0) end
function to_string_sci(bf::MiniBf, digits=0) end

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
        carry /= WORD_SIZE
    end
    
    # Carry out
    if carry != 0
        z.len += 1
        z.tab[z.len] = UInt32(carry)
    end

    z
end
mul(x::MiniBf, y::Unsigned) = mul(x, UInt32(y))

function add(x::MiniBf, y::UInt32, p=0) end
function sub(x::MiniBf, y::UInt32, p=0) end
function mul(x::MiniBf, y::UInt32, p) end
function rcp(x::MiniBf, p) end
function div(x::MiniBf, y::UInt32, p) end


function to_string_trimmed(x::MiniBf, digits) end
function ucmp(x::MiniBf, y::UInt32) end
function uadd(x::MiniBf, y::UInt32, p) end
function usub(x::MiniBf, y::UInt32, p) end

function invsqrt(x::MiniBf, y::UInt32, p) end
