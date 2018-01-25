struct SPSSvariablerecord
    name::Symbol
    vtype::DataType
    width::Int
    label::String
    missing_values::Vector{Float64}
    print::Int32
    write::Int32
end

function readvariablerecord(io::IO, vec::Vector{SPSSvariablerecord})
    v = read(io, Int32, 5)
    if v[1] < 0
        return vec
    end
    vtype, width = v[1] == 0 ? (Float64, 8) : (String, v[1])
    name = Symbol(strip(String(read(io, 8))))
    label = ""
    if Bool(v[2])
        label_len = read(io, Int32)
        label = strip(String(read(io, label_len)))
        if (rem = mod(label_len, 4)) ≠ 0
            skip(io, 4 - rem)
        end
    end
    push!(vec, SPSSvariablerecord(name, vtype, width, label, read(io, Float64, v[3]), v[4], v[5]))
end
