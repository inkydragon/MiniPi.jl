import MiniPi: pi_bsr, Pi


function gen_dpt(to_digits)
    to_digits += 1

    p = (to_digits + 8) / 9
    p = trunc(UInt64, p)

    terms = (p * 0.6346230241342037371474889163921741077188431452678) + 1
    terms = trunc(UInt32, terms)

    to_digits, p, terms
end

@testset "pi_bsr" begin
    P, Q, R = pi_bsr(UInt32(0), UInt32(1), UInt64(3))
    test_to_string("-2.793657715 * 10^9", P)
    test_to_string("1.0939058860032000 * 10^16", Q)
    test_to_string("5.", R)

    P, Q, R = pi_bsr(UInt32(1), UInt32(2), UInt64(3))
    test_to_string("2.54994357387 * 10^11", P)
    test_to_string("8.7512470880256000 * 10^16", Q)
    test_to_string("231.", R)

    P, Q, R = pi_bsr(UInt32(0), UInt32(2), UInt64(3))
    test_to_string("-2.44479889433338740603253065 * 10^26", P)
    test_to_string("9.57304069945956794936328192000000 * 10^32", Q)
    test_to_string("1155.", R)

    to_digits, p, terms = gen_dpt(20)
    P, Q, R = pi_bsr(UInt32(0), terms, p)
    test_to_string("-2.44479889433338740603253065 * 10^26", P, to_digits)
    test_to_string("9.57304069945956794936328192000000 * 10^32", Q, to_digits)
    test_to_string("1155.", R, to_digits)

    to_digits, p, terms = gen_dpt(50)
    P, Q, R = pi_bsr(UInt32(0), terms, p)
    test_to_string(
        "-5.0552984125686101746228994534091499889077848307882335805887375 * 10^61",
        P, to_digits)
    test_to_string(
        "1.97949113784380161370086287723699183824180409892941594624000000000000 * 10^68",
        Q, to_digits)
    test_to_string("3.904125225 * 10^9", R, to_digits)
end


#= Pi Reference data =#

const pi_50 = 
    "3.14159265358979323846264338327950288419716939937510"

const pi_100 = "3." *
    "14159265358979323846264338327950288419716939937510" *
    "58209749445923078164062862089986280348253421170679"

const pi_200 = "3." *
    "14159265358979323846264338327950288419716939937510" *
    "58209749445923078164062862089986280348253421170679" *
    "82148086513282306647093844609550582231725359408128" *
    "48111745028410270193852110555964462294895493038196"

const pi_1000 =
replace("""3.
1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679
8214808651328230664709384460955058223172535940812848111745028410270193852110555964462294895493038196
4428810975665933446128475648233786783165271201909145648566923460348610454326648213393607260249141273
7245870066063155881748815209209628292540917153643678925903600113305305488204665213841469519415116094
3305727036575959195309218611738193261179310511854807446237996274956735188575272489122793818301194912
9833673362440656643086021394946395224737190702179860943702770539217176293176752384674818467669405132
0005681271452635608277857713427577896091736371787214684409012249534301465495853710507922796892589235
4201995611212902196086403441815981362977477130996051870721134999999837297804995105973173281609631859
5024459455346908302642522308253344685035261931188171010003137838752886587533208381420617177669147303
5982534904287554687311595628638823537875937519577818577805321712268066130019278766111959092164201989
""", r"\n" => "")

# pi_1e5[end-99:end]
const pi_1e5_last100 =
"8575016363411314627530499019135646823804329970695770150789337728658035712790913767420805655493624646"

# pi_1e7[end-99:end]
const pi_1e7_last100 =
"7610515549257985759204553246894468742702504639790565326553194060999469787333810631719481735348955897"


@testset "Pi" begin
    @test_throws DomainError Pi(61*10^9)
    
    function pi_str(digits)
        to_digits = Int64(digits)
        to_string(Pi(to_digits), to_digits+1)
    end

    @test pi_50 == pi_str(50)
    @test pi_100 == pi_str(100)
    @test pi_200 == pi_str(200)
    @test pi_1000 == pi_str(1000)
    # 1e5:  0.6s
    @test pi_1e5_last100 == pi_str(1e5)[end-99:end]
    # 1e6:  11.3s
    # 1e7:  147s
    # @test pi_1e7_last100 == pi_str(1e7)[end-99:end]
end
