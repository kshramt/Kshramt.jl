import Base.Test: @test, @test_throws, @test_approx_eq

unshift!(LOAD_PATH, joinpath(dirname(@__FILE__), "..", "src"))
import Kshramt


let
    interpolate_lagrange = Kshramt.make_interpolate_lagrange(((-1, 1), (0, 0), (1, 1)))
    xs = -2:0.1:2
    @test_approx_eq interpolate_lagrange(xs) xs.^2
end


let
    for (i, n) in enumerate((0, 1, 1, 2, 3, 5, 8, 13, 21, 34))
        @test Kshramt.fibonacci(i - 1, Int32)::Int32 == n
    end
end


let
    # `ErrorException` is thrown in a macro expansion phase.
    # Therefore, `@test_throws ErrorException Kshramt.@|>(1, 1)` does not work.
    @test_throws ErrorException eval(:(Kshramt.@|> 1 1))

    inc(x) = x + 1
    @test (Kshramt.@|> 1 inc -(1)) == 1
    x = Kshramt.@|> 1 inc inc
    @test x == 3
end


let
    i32(s::AbstractString) = parseint(Int32, s)
    i32(x::Number) = Int32(x)
    i64(s::AbstractString) = parseint(Int64, s)
    i64(x::Number) = Int64(x)
    parse = Kshramt.make_parse_fixed_width(((:a, 2, i32), ("a", 3, i64)))
    d = parse("12345")
    @test d[:a] == 12
    @test typeof(d[:a]) == Int32
    @test d["a"] == 345
    @test typeof(d["a"]) == Int64
    d = parse("123456")
    @test d[:a] == 12
    @test typeof(d[:a]) == Int32
    @test d["a"] == 345
    @test typeof(d["a"]) == Int64

    @test_throws AssertionError parse("1234")
    @test_throws TypeError Kshramt.make_parse_fixed_width(((:a, 2.0, i32), ("a", 3, i64)))

    parse = Kshramt.make_parse_fixed_width(((:a, 1, i32), 2, (3, 3, symbol)))
    @test parse("123456") == Dict(:a => i32(1), 3 => symbol("456"))
end


let
    @test Kshramt.one_others([]) == []
    @test Kshramt.one_others([1]) == [(1, [])]
    @test Kshramt.one_others([1, 2]) == [(1, [2]), (2, [1])]
    @test Kshramt.one_others([1, 2, 3]) == [(1, [2, 3]), (2, [1, 3]), (3, [1, 2])]
    @test Kshramt.one_others([1, 2, 3, 4]) == [(1, [2, 3, 4]), (2, [1, 3, 4]), (3, [1, 2, 4]), (4, [1, 2, 3])]
end

let
    @test Kshramt.count_by(typeof, Any[1, 2.0, 3]) == Dict(
                                                           Float64 => 1,
                                                           Int64 => 2,
                                                           )
end

let
    @test Kshramt.group_by(typeof, Any[1, 2.0, 3]) == Dict(
                                                           Float64 => [2.0],
                                                           Int64 => [1, 3],
                                                           )
end

let
    @test_throws AssertionError Kshramt.each_cons([1, 2, 3, 4], 0)
    @test Kshramt.each_cons([1, 2, 3, 4], 1) == [[i] for i in [1, 2, 3, 4]]
    @test Kshramt.each_cons([1, 2, :a, 4], 1) == [[i] for i in [1, 2, :a, 4]]
    @test Kshramt.each_cons([1, 2, 3, 4], 2) == [[i, j] for (i, j) in [(1, 2), (2, 3), (3, 4)]]
    @test Kshramt.each_cons([1, 2, 3, 4], 3) == [[i, j, k] for (i, j, k) in [(1, 2, 3), (2, 3, 4)]]
    @test Kshramt.each_cons((1, 2, 3, 4), 3) == [(i, j, k) for (i, j, k) in [(1, 2, 3), (2, 3, 4)]]
    @test Kshramt.each_cons([1, 2, 3, 4], 4) == [[i, j, k, l] for (i, j, k, l) in [(1, 2, 3, 4)]]
    @test Kshramt.each_cons([1, 2, 3, 4], 5) == []
end
