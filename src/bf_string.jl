# SPDX-License-Identifier: MIT
# Based on Mysticial/Mini-Pi/decomposed/src/BigFloat.cpp
#   Author: Alexander J. Yee, CC0-1.0 License
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
