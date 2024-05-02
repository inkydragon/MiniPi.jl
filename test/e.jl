import MiniPi: Exp



#= Pi Reference data =#

const e_50 = "2.71828182845904523536028747135266249775724709369995"

const e_100 = "2." *
    "71828182845904523536028747135266249775724709369995" *
    "95749669676277240766303535475945713821785251664274"

const e_200 = "2." *
    "71828182845904523536028747135266249775724709369995" *
    "95749669676277240766303535475945713821785251664274" *
    "27466391932003059921817413596629043572900334295260" *
    "59563073813232862794349076323382988075319525101901"


@testset "e" begin
    @test_throws DomainError Exp(61*10^9)

    function e_str(digits)
        to_digits = Int64(digits)
        to_string(Exp(to_digits), to_digits+1)
    end

    @test e_50 == e_str(50)
    @test e_100 == e_str(100)
    @test e_200 == e_str(200)

end