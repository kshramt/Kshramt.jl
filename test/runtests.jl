import Base.Test: @test, @test_throws, @test_approx_eq, @test_approx_eq_eps

unshift!(LOAD_PATH, joinpath(dirname(@__FILE__), "..", "src"))
import Kshramt


let
    x, y = Kshramt.ternary_diagram(1, 0, 0)
    @test_approx_eq x 0.5
    @test_approx_eq y √3/2
    x, y = Kshramt.ternary_diagram(0, 1, 0)
    @test_approx_eq x 0
    @test_approx_eq y 0
    x, y = Kshramt.ternary_diagram(0, 0, 1)
    @test_approx_eq x 1
    @test_approx_eq y 0
    x, y = Kshramt.ternary_diagram(1, 1, 1)
    @test_approx_eq x 0.5
    @test_approx_eq y √3/2/3
    x, y = Kshramt.ternary_diagram(0, 1, 1)
    @test_approx_eq x 0.5
    @test_approx_eq y 0
end


let
    s = Kshramt.LineSearchState(Float64)
    for x0 in (10, -20, 0.75, 100)
        f_best = Inf
        x_best = Inf
        x = Inf
        Kshramt.init(s)
        while true
            x = s.x
            f = 1 - 1/(1 + (x - x0)^2)
            println(s.iter, '\t', x, '\t', s.xl, '\t', s.xr, '\t', f, '\t', s.fl, '\t', s.fr)
            Kshramt.update(s, f)
            converge = abs(f_best - f) < 1e-6 && abs(s.x - x_best) < 1e-3 && s.iter > 4 && s.is_quadrantic
            if f < f_best
                f_best = f
                x_best = x
            end
            converge && break
        end
        @test_approx_eq_eps x x0 1e-2
    end
end


let
    let
        x, is_quadrantic = Kshramt.line_search_quadratic(-2, 1, 2, 4, 1, 4)
        @test is_quadrantic
        @test_approx_eq x 0
    end
    let
        x, is_quadrantic = Kshramt.line_search_quadratic(-2, 1, 3, -4, -1, -9)
        @test !is_quadrantic
        @test_approx_eq x 3
    end
    let
        x, is_quadrantic = Kshramt.line_search_quadratic(-1, 0, 2, -1, 0, 2)
        @test !is_quadrantic
        @test_approx_eq x -1
    end
end


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
    i32(s::AbstractString) = parse(Int32, s)
    i32(x::Number) = Int32(x)
    i64(s::AbstractString) = parse(Int64, s)
    i64(x::Number) = Int64(x)
    parse_fixed_width = Kshramt.make_parse_fixed_width(((:a, 2, i32), ("a", 3, i64)))
    d = parse_fixed_width("12345")
    @test d[:a] == 12
    @test typeof(d[:a]) == Int32
    @test d["a"] == 345
    @test typeof(d["a"]) == Int64
    d = parse_fixed_width("123456")
    @test d[:a] == 12
    @test typeof(d[:a]) == Int32
    @test d["a"] == 345
    @test typeof(d["a"]) == Int64

    @test_throws AssertionError parse_fixed_width("1234")
    @test_throws TypeError Kshramt.make_parse_fixed_width(((:a, 2.0, i32), ("a", 3, i64)))

    parse_fixed_width = Kshramt.make_parse_fixed_width(((:a, 1, i32), 2, (3, 3, symbol)))
    @test parse_fixed_width("123456") == Dict(:a => i32(1), 3 => symbol("456"))
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
