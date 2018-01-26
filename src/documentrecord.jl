function readdocumentrecord(io::IO)
    n = read(io, Int32)
    skip(io, 80 * n)
    return read(io, Int32)
end