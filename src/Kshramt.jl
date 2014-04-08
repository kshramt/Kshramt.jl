module Kshramt

one_others(xs) = [(xs[i], [xs[1:i-1], xs[i+1:end]]) for i in 1:length(xs)]

count_by(f, xs) = [k => length(vs) for (k, vs) in group_by(f, xs)]

function group_by(f, xs)
    ret = Dict()
    for x in xs
        k = f(x)
        if haskey(ret, k)
            push!(ret[k], x)
        else
            ret[k] = [x]
        end
    end
    ret
end

function each_cons(xs, n)
    @assert n >= 1
    m = n - 1
    [xs[i:i+m] for i in 1:(length(xs) - m)]
end

end
