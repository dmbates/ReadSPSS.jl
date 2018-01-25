function readlabels(io::IO, bias::Int=100)
    n = read(io, Int32)
    dictf = sizehint!(Dict{Float64, String}(), n)
    dictui = sizehint!(Dict{UInt8, String}(), n)
    for i = 1:n
        k = read(io, Float64)
        nchar = read(io, Int8)
        label = String(read(io, nchar))
        extras = rem(nchar + 1, 8)
        if extras ≠ 0
            skip(io, 8 - extras)
        end
        dictf[k] = label
        if isinteger(k)
            kb = Int(k) + bias
            if 0 < kb < 252
                dictui[kb] = label
            end
        end
    end
    read(io, Int32) == 4 || throw(ArgumentError("Malformed stream"))
    dictf, dictui, read(io, Int32, read(io, Int32))
end
