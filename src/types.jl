struct SPSSheader
    compression_code::Int8
    prod_name::String
    nominal_case_size::Int32
    weight_index::Int32
    ncases::Int32
    bias::Float64
    creation_date::String
    creation_time::String
    file_label::String
end

function SPSSheader(io::IO)
    (String(read(io, 3)) == "\$FL" && (compchar = read(io, UInt8)) ∈ [0x32, 0x33]) ||
        throw(ArgumentError("""Stream must start with "\$FL2" or "\$FL3" """))
    prodname = strip(String(read(io, 60)))
    layout_code = read(io, Int32)
    nominal_case_size = read(io, Int32)
    compression = read(io, Int32)
    weight_index = read(io, Int32)
    ncases = read(io, Int32)
    bias = read(io, Float64)
    creation_date = strip(String(read(io, 9)))
    creation_time = strip(String(read(io, 8)))
    file_label = strip(String(read(io, 64)))
    skip(io, 3)
    SPSSheader(Int8(compression), prodname, nominal_case_size, weight_index,
              ncases, bias, creation_date, creation_time, file_label)
end

struct SPSSvariablerecord
    name::Symbol
    vtype::DataType
    width::Int
    label::String
    missing_values::Vector{Float64}
    print::Int32
    write::Int32
end
function SPSSvariablerecord(io::IO)
    vals = read(io, Int32, 6)
    vals[1] == 2 || throw(ArgumentError("Stream should be at rec_type 2"))
    vtype = String
    width = vals[2]
    if width == 0
        vtype = Float64
        width = 8
    end
    name = Symbol(strip(String(read(io, 8))))
    label = ""
    if Bool(vals[3])
        label_len = read(io, Int32)
        label = strip(String(read(io, label_len)))
        if (rem = mod(label_len, 4)) ≠ 0
            skip(io, 4 - rem)
        end
    end
    SPSSvariablerecord(name, vtype, width, label, read(io, Float64, vals[4]), vals[5], vals[6])
end

    

end
struct SPSSDataFrame
    data::Vector{Any}
    colnames::Vector{Symbol}
end

