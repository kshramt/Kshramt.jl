module Kshramt


type LineSearchState{T}
    is_quadrantic::Bool
    iter::Int
    xl::T
    x::T
    xr::T
    fl::T
    f::T
    fr::T
end
LineSearchState{T}(::Type{T}) = LineSearchState(false, -1, T(0), T(1), T(1), convert(T, Inf), convert(T, Inf), convert(T, Inf))
LineSearchState() = LineSearchState(Float64)


@doc """
  x
 / \
y---z
0   1
""" ->
function ternary_diagram{S, T, U}(x::S, y::T, z::U)
    @assert x >= 0
    @assert y >= 0
    @assert z >= 0
    total = x + y + z
    ax = x/total
    (z/total + ax/2, √3*ax/2)
end
ternary_diagram{S, T, U}(xs::Array{S}, ys::Array{T}, zs::Array{U}) = map(ternary_diagram, xs, ys, zs)
ternary_diagram{S, T, U}(xyz::(S, T, U)) = ternary_diagram(xyz...)
ternary_diagram{S, T, U}(xyzs::Array{(S, T, U)}) = map(ternary_diagram, xyzs)


macro ltsv(vs...)
    args = []
    for v in vs[1:end-1]
        append!(args, [Meta.quot(v), :(':'), v, '\t'])
    end
    v = vs[end]
    append!(args, [Meta.quot(v), :(':'), v])
    esc(:(println($(args...))))
end


function init(s::LineSearchState)
    s.is_quadrantic = false
    s.iter = 0
    s.xl = 0
    s.xr = 1
    s.x = s.xl
end


function update{T}(s::LineSearchState{T}, f::T, enlarge::T=T(11//10))
    s.iter < 0 && throw("$s should be `init`ialized before `update`d")
    s.iter += 1
    if s.iter == 1
        s.xl = s.x
        s.fl = f
        s.x = s.xl + 1
        return
    elseif s.iter == 2
        @assert s.x > s.xl
        s.xr = s.x
        s.fr = f
        step = enlarge*(s.xr - s.xl)
        s.x = s.fr < s.fl ? s.xr + step : s.xl - step
        return
    elseif s.x == s.xl || s.x == s.xr
        step = enlarge*(s.xr - s.xl)
        s.x = s.fl < s.fr ? s.xl - step : s.xr + step
        return
    end
    xs = [s.xl, s.x, s.xr]
    inds = sortperm(xs)
    x1, x2 ,x3 = xs[inds]
    f1, f2, f3 = [s.fl, f, s.fr][inds]

    x_new, s.is_quadrantic = line_search_quadratic(x1, x2, x3, f1, f2, f3)
    step = enlarge*(x3 - x1)
    if s.is_quadrantic
        if x_new < x1
            _update(s, x1, x2, f1, f2, max(x_new, x1 - step))
        elseif x_new == x1
            _update(s, x1, x2, f1, f2, x1 - step)
        elseif x3 < x_new
            _update(s, x2, x3, f2, f3, min(x_new, x3 + step))
        elseif x3 == x_new
            _update(s, x2, x3, f2, f3, x3 + step)
        elseif x2 == x_new
            if f1 < f3
                _update(s, x1, x2, f1, f2, (x1/2) + (x2/2))
            else
                _update(s, x2, x3, f2, f3, (x2/2) + (x3/2))
            end
        else
            if f1 < f3
                _update(s, x1, x2, f1, f2, x_new)
            else
                _update(s, x2, x3, f2, f3, x_new)
            end
        end
    else
        if x_new < x2
            _update(s, x1, x2, f1, f2, x1 - step)
        else
            _update(s, x2, x3, f2, f3, x3 + step)
        end
    end
end


function _update{T}(s::LineSearchState{T}, xl::T, xr::T, fl::T, fr::T, x::T)
    s.xl = xl
    s.xr = xr
    s.fl = fl
    s.fr = fr
    s.x = x
end


function line_search_quadratic(x1, x2, x3, f1, f2, f3)
    x12 = x1 - x2
    x13 = x1 - x3
    x23 = x2 - x3
    f1x1213 = f1/(x12*x13)
    f2x1223 = f2/(x12*x23)
    f3x1323 = f3/(x13*x23)
    a = f1x1213 - f2x1223 + f3x1323
    is_quadrantic = a > 0
    if is_quadrantic
        neg_b = f1x1213*(x2 + x3) - f2x1223*(x1 + x3) + f3x1323*(x1 + x2)
        neg_b/2a
    elseif f1 < f2
        if f1 < f3
            x1
        else
            x3
        end
    elseif f2 < f3
        x2
    else
        x3
    end, is_quadrantic
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
