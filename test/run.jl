import Base.Test: @test, @test_throws

unshift!(LOAD_PATH, joinpath(dirname(@__FILE__), "..", "src"))
import Kshramt

let
    # `Kshramt.Error` is thrown in a macro expansion phase.
    # Therefore, `@test_throws Kshramt.Error Kshramt.@|>(1, 1)` is not enough.
    @test_throws Kshramt.Error eval(:(Kshramt.@|>(1, 1)))

    inc(x) = x + 1
    @test Kshramt.@|>(1, inc, -(1)) == 1
end

let
    @test Kshramt.one_others([]) == []
    @test Kshramt.one_others([1]) == [(1, [])]
    @test Kshramt.one_others([1, 2]) == [(1, [2]), (2, [1])]
    @test Kshramt.one_others([1, 2, 3]) == [(1, [2, 3]), (2, [1, 3]), (3, [1, 2])]
    @test Kshramt.one_others([1, 2, 3, 4]) == [(1, [2, 3, 4]), (2, [1, 3, 4]), (3, [1, 2, 4]), (4, [1, 2, 3])]
end

let
    @test Kshramt.count_by(typeof, {1, 2.0, 3}) == {
                                                    Float64 => 1,
                                                    Int64 => 2,
                                                    }
end

let
    @test Kshramt.group_by(typeof, {1, 2.0, 3}) == {
                                                    Float64 => [2.0],
                                                    Int64 => [1, 3],
                                                    }
end

let
    @test_throws ErrorException Kshramt.each_cons([1, 2, 3, 4], 0)
    @test Kshramt.each_cons([1, 2, 3, 4], 1) == [[i] for i in [1, 2, 3, 4]]
    @test Kshramt.each_cons([1, 2, :a, 4], 1) == [[i] for i in [1, 2, :a, 4]]
    @test Kshramt.each_cons([1, 2, 3, 4], 2) == [[i, j] for (i, j) in [(1, 2), (2, 3), (3, 4)]]
    @test Kshramt.each_cons([1, 2, 3, 4], 3) == [[i, j, k] for (i, j, k) in [(1, 2, 3), (2, 3, 4)]]
    @test Kshramt.each_cons((1, 2, 3, 4), 3) == [(i, j, k) for (i, j, k) in [(1, 2, 3), (2, 3, 4)]]
    @test Kshramt.each_cons([1, 2, 3, 4], 4) == [[i, j, k, l] for (i, j, k, l) in [(1, 2, 3, 4)]]
    @test Kshramt.each_cons([1, 2, 3, 4], 5) == []
end
