
struct MiniBf <: AbstractFloat end

function MiniBf() end
function MiniBf(bf::MiniBf) end
function MiniBf(x::UInt32, sign=true) end

function to_string(bf::MiniBf, digits=0) end
function to_string_sci(bf::MiniBf, digits=0) end

function get_precision(bf::MiniBf) end
function get_exponent(bf::MiniBf) end
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
