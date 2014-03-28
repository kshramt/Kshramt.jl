import Base.Test: @test, @test_throws

unshift!(LOAD_PATH, joinpath(dirname(@__FILE__), "..", "src"))
import Kshramt

let
    @test_throws Kshramt.each_cons([1, 2, 3, 4], 0)
    @test Kshramt.each_cons([1, 2, 3, 4], 1) == [[i] for i in [1, 2, 3, 4]]
    @test Kshramt.each_cons([1, 2, :a, 4], 1) == [[i] for i in [1, 2, :a, 4]]
    @test Kshramt.each_cons([1, 2, 3, 4], 2) == [[i, j] for (i, j) in [(1, 2), (2, 3), (3, 4)]]
    @test Kshramt.each_cons([1, 2, 3, 4], 3) == [[i, j, k] for (i, j, k) in [(1, 2, 3), (2, 3, 4)]]
    @test Kshramt.each_cons((1, 2, 3, 4), 3) == [(i, j, k) for (i, j, k) in [(1, 2, 3), (2, 3, 4)]]
    @test Kshramt.each_cons([1, 2, 3, 4], 4) == [[i, j, k, l] for (i, j, k, l) in [(1, 2, 3, 4)]]
    @test Kshramt.each_cons([1, 2, 3, 4], 5) == []
end
