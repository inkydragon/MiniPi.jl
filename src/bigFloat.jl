# SPDX-License-Identifier: MIT
# Based on Mysticial/Mini-Pi/decomposed/src/BigFloat.cpp
#   Author: Alexander J. Yee, CC0-1.0 License

"Precision increase step."
const EXTRA_PRECISION = UInt64(2)
"Word size = 10^9"
const WORD_SIZE = UInt32(1_000_000_000)
"Word max"
const WORD_MAX = UInt32(1_000_000_000 - 1)

# BfCmp
const BF_SMALLER = -1
const BF_EQUAL = 0
const BF_LARGER = 1


function check_word_size(x)
    if x >= WORD_SIZE
        err_msg = "Only impl MiniBf() for x($x) < WORD_SIZE($WORD_SIZE)"
        throw(DomainError("x too large. $err_msg"))
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
    # len = 1,                     vvv~~~~~~~~
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


Base.zero(::Type{MiniBf}) = MiniBf()
Base.one(::Type{MiniBf}) = MiniBf(1)


#= Setters =#

"""
Set x to zero.
"""
function zero!(x::MiniBf)
    x.sign = true
    x.exp = 0
    x.len = 0
end


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
    magnitude(x::MiniBf)

Get magnitude.
"""
function _magnitude(x::MiniBf) :: Int64
    x.exp + Int64(x.len)
end

"""
Return x sign.
"""
function Base.sign(x::MiniBf)
    if iszero(x.len)
        0
    elseif x.sign
        1
    else
        -1
    end
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
"""
function word_at(x::MiniBf, mag::Int64)
    @assert length(x.tab) >= x.len

    idx = Int(mag - x.exp)
    if idx < 0 || idx >= x.len
        return 0
    end

    return x.tab[idx + 1]
end

function Base.getindex(x::MiniBf, mag::Int64)
    word_at(x, mag)
end


#= Compare Ops =#

"""
If x is zero.
"""
function Base.iszero(x::MiniBf)
    iszero(x.len)
end

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
    magA = _magnitude(x)
    magB = _magnitude(y)

    if magA > magB
        return BF_LARGER
    elseif magA < magB
        return BF_SMALLER
    end

    mag = magA
    while mag >= x.exp || mag >= y.exp
        wordA = word_at(x, mag)
        wordB = word_at(y, mag)
        if wordA < wordB
            return BF_SMALLER
        elseif wordA > wordB
            return BF_LARGER
        end

        mag -= 1
    end
    
    return BF_EQUAL
end
