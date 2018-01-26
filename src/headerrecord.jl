function readheader(io::IO)
    (String(read(io, 3)) == "\$FL" && (compchar = read(io, UInt8)) ∈ [0x32, 0x33]) ||
        throw(ArgumentError("""Stream must start with "\$FL2" or "\$FL3" """))
    prodname = strip(String(read(io, 60)))
    layout_code = read(io, Int32)
    casesz = read(io, Int32)
    compression = read(io, Int32)
    weight_index = read(io, Int32)
    ncases = read(io, Int32)
    bias = Int(read(io, Float64))  # stored as Float64 but only meaningful as an Int
    creation_date = strip(String(read(io, 9)))
    creation_time = strip(String(read(io, 8)))
    file_label = strip(String(read(io, 64)))
    skip(io, 3)
    (compression, bias, casesz, ncases, prodname, creation_date, creation_time, file_label)
end
