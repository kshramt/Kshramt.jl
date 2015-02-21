module Kshramt


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


function make_parse_fixed_width(fields)
    n = 1
    _fields = []
    for field in fields
        if isa(field, Integer)
            n += field
        else
            name, len, fn = field::(Any, Integer, Function)
            n += len
            push!(_fields, :($(Meta.quot(name)) => ($fn)(s[$(n-len):$(n-1)])))
        end
    end
    ex = :((s)->(@assert length(s) >= $(n-1); Dict()))
    append!(ex.args[2].args[2].args[2].args, _fields)
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
            error("$f::$(typeof(f)) is neither `Expr` nor `Symbol`")
        end
        _pipe(_v, fs[2:end])
    end
end

one_others(xs) = [(xs[i], [xs[1:i-1]; xs[i+1:end]]) for i in 1:length(xs)]

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
