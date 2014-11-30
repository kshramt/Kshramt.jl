module Kshramt


type Error <: Exception
    msg::String
end
error(s::String) = throw(Error(s))
error(s...) = error(string(s...))
Base.showerror(io::IO, e::Error) = print(io, e.msg)


function make_parse_fixed_width(fields)
    n = 1
    _fields = map(fields) do field
        name, len, fn = field::(Any, Integer, Function)
        n += len
        :($(Meta.quot(name)) => ($fn)(s[$(n-len):$(n-1)]))
    end
    ex = :((s)->(@assert length(s) >= $(n-1); Dict()))
    append!(ex.args[2].args[2].args[2].args, [_fields...])
    eval(ex)
end


macro |>(v, fs...)
    esc(_pipe(v, fs))
end
function _pipe(v, fs)
    if length(fs) <= 0
        v
    else
        f = fs[1]
        _v = if isa(f, Expr)
            @assert f.head == :call
            insert!(f.args, 2, v)
            f
        elseif isa(f, Symbol)
            :($f($v))
        else
            error("Unsupported type: $f::$(typeof(f))")
        end
        _pipe(_v, fs[2:end])
    end
end

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
