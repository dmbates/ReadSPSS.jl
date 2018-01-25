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

function readheader(io::IO)
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
