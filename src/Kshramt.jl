module Kshramt

function each_cons(xs, n::Int)
    @assert n >= 1
    m = n - 1
    [xs[i:i+m] for i in 1:length(xs) - m]
end

end
