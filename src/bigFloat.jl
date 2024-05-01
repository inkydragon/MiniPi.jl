
"Precision increase step."
const EXTRA_PRECISION = UInt64(2)
"Word size = 10^9"
const WORD_SIZE = UInt32(1_000_000_000)
"Word max"
const WORD_MAX = UInt32(1_000_000_000 - 1)

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
function _magnitude(x::MiniBf) :: Int
    x.exp + Int(x.len)
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
    @assert length(x.tab) >= x.len

    idx = Int(mag - x.exp)
    if idx < 0 || idx >= x.len
        return 0
    end

    return x.tab[idx + 1]
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
        return 1
    elseif magA < magB
        return -1
    end

    mag = magA
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


#= String Conversion =#

"""
    to_string_trimmed!(str::Vector{UInt8}, x::MiniBf, to_digits::Int64)

Converts this object to a string with "digits" significant figures.

After calling this function, the following expression is equal to the
numeric value of this object. (after truncation of precision)
    str + " * 10^" + (return value)
"""
function to_string_trimmed!(str::Vector{UInt8}, x::MiniBf, to_digits::Int64)
    str_len = 0
    if iszero(x.len)
        resize!(str, 1)
        str[1] = '0'
        expo = 0
        return expo
    end

    # Collect operands
    expo = x.exp
    len = x.len

    idx_chop = 0
    if iszero(to_digits)
        # Use all to_digits.
        to_digits = len * 9
    else
        # Truncate precision
        words = div(to_digits + 17, 9)
        if words < len
            chop = len - words
            expo += Int64(chop)
            len = words
            idx_chop = chop
        end
    end
    expo *= 9

    # Alloc big enough buffer
    resize!(str, len*9)
    # Build string
    buffer = UInt8['0','1','2','3','4','5','6','7','8']
    c = len
    while c > 0
        c -= 1
        word = x.tab[idx_chop+c+1]
        for i in 9:-1:1
            buffer[i] = UInt8(word % 10) + '0'
            word = div(word, 10)
        end
        str[(str_len+1):(str_len+9)] = buffer
        str_len += 9
    end

    # Count leading zeros
    leading_zeros = 0
    for i in 1:str_len
        if str[i] != UInt8('0')
            break
        end
        leading_zeros += 1
    end
    to_digits += leading_zeros

    # Truncate
    if to_digits < str_len
        expo += str_len - to_digits
        resize!(str, to_digits)
    end

    return expo
end

"""
    to_string_sci!(u8::Vector{UInt8}, x::MiniBf, to_digits::Int64)

Convert to string in scientific notation.
"""
function to_string_sci!(u8::Vector{UInt8}, x::MiniBf, to_digits=Int64(0))
    str_len = 0

    # Convert to string in scientific notation.
    if iszero(x.len)
        str_len = 2
        resize!(u8, str_len)
        u8[1:str_len] = UInt8['0', '.']

        return String(Char.(u8))
    end

    # Convert
    expo = to_string_trimmed!(u8, x, to_digits)
    str = String(Char.(u8))

    # Strip leading zeros.
    leading_zeros = 0
    for c in str
        if c != '0'
            break
        end
        leading_zeros += 1
    end
    str = str[leading_zeros+1:end]

    # Insert decimal place
    expo += length(str) - 1
    str = str[1] * "." * str[2:end]

    # Add exponent
    if expo != 0
        str *= " * 10^" * string(expo)
    end

    # Add sign
    if !x.sign
        str = "-" * str
    end

    return str
end

"""
    to_string(x::MiniBf, to_digits::Int64)

Convert this number to a string. Auto-select format type.
"""
function to_string(x::MiniBf, to_digits=Int64(0))
    if iszero(x.len)
        return "0."
    end

    mag = x.exp + x.len

    u8 = zeros(UInt8, to_digits)
    # Use scientific notation if out of range.
    if mag > 1 || mag < 0
        return to_string_sci!(u8, x)
    end

    # Convert
    expo = to_string_trimmed!(u8, x, to_digits)
    str = String(Char.(u8))

    # Less than 1
    if iszero(mag)
        if x.sign
            return "0." * str
        else
            return "-0." * str
        end
    end

    # Get a string with the to_digits before the decimal place.
    before_decimal = string(x.tab[x.len])

    # Nothing after the decimal place.
    if expo >= 0
        if x.sign
            return before_decimal * "."
        else
            return "-" * before_decimal * "."
        end
    end

    # Get to_digits after the decimal place.
    after_decimal = str[length(str) + expo + 1:end]

    if x.sign
        return before_decimal * "." * after_decimal
    else
        return "-" * before_decimal * "." * after_decimal
    end
end
