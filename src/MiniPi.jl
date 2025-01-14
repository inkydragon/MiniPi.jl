# SPDX-License-Identifier: MIT
module MiniPi

include("fft.jl")
using .FFT

include("bigFloat.jl")
include("bf_string.jl")
include("bf_math.jl")

include("pi.jl")
include("e.jl")

end
