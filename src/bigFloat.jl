
"Precision increase step."
const EXTRA_PRECISION = UInt64(2)

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

Base.:(==)(x::MiniBf, y::MiniBf) =
    x.sign == y.sign &&
    x.exp == y.exp &&
    x.len == y.len &&
    x.tab == y.tab


function to_string(bf::MiniBf, digits=0) end
function to_string_sci(bf::MiniBf, digits=0) end

"""
    precision(x::MiniBf)

Returns the precision of the number in words.

Note that each word is 9 decimal digits.
"""
function Base.precision(x::MiniBf)
    x.len
end

"""
    exponent(x::MiniBf)
    
Returns the exponent of the number in words.

Note that each word is 9 decimal digits.
"""
function Base.exponent(x::MiniBf)
    x.exp
end

function word_at(mag::UInt64) end

function negate(bf::MiniBf) end
function mul(bf::MiniBf) end
function add(bf::MiniBf, x::UInt32, p=0) end
function sub(bf::MiniBf, x::UInt32, p=0) end
function mul(bf::MiniBf, x::UInt32, p=0) end
function rcp(bf::MiniBf, p) end
function div(bf::MiniBf, x::UInt32, p) end


function to_string_trimmed(bf::MiniBf, digits) end
function ucmp(bf::MiniBf, x::UInt32) end
function uadd(bf::MiniBf, x::UInt32, p) end
function usub(bf::MiniBf, x::UInt32, p) end

function invsqrt(bf::MiniBf, x::UInt32, p) end
