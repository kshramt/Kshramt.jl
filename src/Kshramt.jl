module Kshramt


macro ltsv(vs...)
    args = []
    for v in vs[1:end-1]
        append!(args, [Meta.quot(v), :(':'), v, '\t'])
    end
    v = vs[end]
    append!(args, [Meta.quot(v), :(':'), v])
    esc(:(println($(args...))))
end


make_interpolate_hermite(xyyps) = eval(_make_interpolate_hermite(xyyps))
function _make_interpolate_hermite(xyyps)
    n = length(xyyps)
    xs = [xyyp[1] for xyyp in xyyps]
    @assert length(unique(xs)) == n
    terms = []
    for k in 1:n
        xk, yk, ypk = xyyps[k]
        Lk_x = _get_Lk(k, :x, xs)
        Lkp_xk = reduce_exs(:+, [:(1/($xk - $x)) for x in but_nth(xs, k)])
        push!(terms, :(($yk*(1 - 2*$Lkp_xk*(x - $xk)) + $ypk*(x - $xk)).*$Lk_x.^2))
    end
    quote
        function $(gensym(:interpolate_hermite))(x)
            $(reduce_exs(:+, terms))
        end
    end
end


make_interpolate_lagrange(xys) = eval(_make_interpolate_lagrange(xys))
function _make_interpolate_lagrange(xys)
    n = length(xys)
    @assert length(unique([xy[1] for xy in xys])) == n
    xs = [xy[1] for xy in xys]
    ys = [xy[2] for xy in xys]
    terms = []
    for k in 1:n
        yk = ys[k]
        if yk != 0
            push!(terms, :($yk*$(_get_Lk(k, :x, xs))))
        end
    end
    quote
        function $(gensym(:interpolate_lagrange))(x)
            $(reduce_exs(:+, terms))
        end
    end
end


function _get_Lk(k, x, xs)
    xk = xs[k]
    xsbutkth = but_nth(xs, k)
    :($(_get_mul_poly(:x, xsbutkth))/$(_get_mul_poly(xk, xsbutkth)))
end


_get_mul_poly(x, xis) = reduce_exs(:.*, [xi == 0 ? x : :($x - $xi) for xi in xis])


function reduce_exs(op, exs)
    n = length(exs)
    @assert n > 0
    if n == 1
        exs[1]
    elseif n == 2
        :($op($(exs...)))
    else
        m = n >> 1
        :($op($(reduce_exs(op, exs[1:m])), $(reduce_exs(op, exs[m+1:end]))))
    end
end


const sqrt5 = sqrt(5)
const λ₁ = (1 + sqrt5)/2
const λ₂ = (1 - sqrt5)/2
fibonacci(x::Integer) = fibonacci(x, Int)
fibonacci{T}(x::Integer, ::Type{T}) = round(T, (λ₁^x - λ₂^x)/sqrt5)


function dump_vtk_structured_points{T, U}(io::IO, vs::AbstractArray{T, 3}, dx::U, dy::U, dz::U, x0::U, y0::U, z0::U)
    @assert dx > zero(U)
    @assert dy > zero(U)
    @assert dz > zero(U)
    nx, ny, nz = size(vs)
    @assert nx >= 1
    @assert ny >= 1
    @assert nz >= 1
    println(io, """# vtk DataFile Version 3.0
voxel
ASCII
DATASET STRUCTURED_POINTS
DIMENSIONS $nx $ny $nz
ORIGIN $x0 $y0 $z0
SPACING $dx $dy $dz
POINT_DATA $(length(vs))
SCALARS v $(_vtk_type(T))
LOOKUP_TABLE default""")
    for v in vs
        print(io, v, '\n')
    end
end
dump_vtk_structured_points{T, U}(io::IO, vs::AbstractArray{T, 3}, dx::U, dy::U, dz::U) = dump_vtk_structured_points(io, vs, dx, dy, dz, zero(U), zero(U), zero(U))
dump_vtk_structured_points{T}(io::IO, vs::AbstractArray{T, 3}) = dump_vtk_structured_points(io, vs, 1e0, 1e0, 1e0)
dump_vtk_structured_points{T}(vs::AbstractArray{T, 3}) = dump_vtk_structured_points(STDOUT, vs)


_vtk_type(::Type{Float16}) = "FLOAT"
_vtk_type(::Type{Float32}) = "FLOAT"
_vtk_type(::Type{Float64}) = "FLOAT"
_vtk_type(::Type{Int8}) = "INTEGER"
_vtk_type(::Type{Int16}) = "INTEGER"
_vtk_type(::Type{Int32}) = "INTEGER"
_vtk_type(::Type{Int64}) = "INTEGER"
_vtk_type(::Type{Int128}) = "INTEGER"


make_parse_fixed_width(fields) = eval(_make_parse_fixed_width(fields))
function _make_parse_fixed_width(fields)
    n = 1
    n_max = n
    _fields = []
    for field in fields
        if isa(field, Integer)
            n += field
        else
            name, len, fn = field::(Any, Integer, Any)
            n += len
            push!(_fields, :($(Meta.quot(name)) => ($fn)(s[$(n-len):$(n-1)])))
        end
        n > n_max && (n_max = n)
    end
    quote
        function $(gensym(:parse_fixed_width))(s)
            @assert length(s) >= $(n_max - 1)
            Dict($(_fields...))
        end
    end
end


macro |>(v, fs...)
    esc(_pipe(v, fs))
end
function _pipe(v, fs)
    for f in fs
        v = if isa(f, Expr)
            @assert f.head == :call
            insert!(f.args, 2, v)
            f
        elseif isa(f, Symbol)
            :($f($v))
        else
            error("$f::$(typeof(f)) is neither `Expr` nor `Symbol`")
        end
    end
    v
end

one_others(xs) = [(xs[i], but_nth(xs, i)) for i in 1:length(xs)]


function but_nth(xs, n)
    [xs[1:n-1]; xs[n+1:end]]
end


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
