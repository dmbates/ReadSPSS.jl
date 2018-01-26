function readlabelset(io::IO, bytecomp::Bool, bias::Integer)
    n = read(io, Int32)
    dictf = sizehint!(Dict{Float64, String}(), n)
    dictui = sizehint!(Dict{UInt8, String}(), n)
    for i = 1:n
        k = read(io, Float64)
        nchar = read(io, Int8)
        label = String(read(io, nchar))
                     # advance io to next multiple of 8 bytes
        extras = rem(nchar + 1, 8)   # + 1 b/c of reading nchar
        if extras ≠ 0
            skip(io, 8 - extras)
        end
        dictf[k] = label
        if bytecomp && isinteger(k)
            kb = Int(k) + bias
            if 0 < kb < 252
                dictui[kb] = label
            end
        end
    end
    read(io, Int32) == 4 || throw(ArgumentError("Malformed stream"))
    inds = read!(io, Vector{Int32}(read(io, Int32)))
    dictf, dictui, inds
end

function readvaluelabels!(io::IO, vdict::VariableDictionary, bytecomp::Bool, bias::Integer)
    rectyp = Int32(3)
    nms = vdict.nms
    typs = vdict.typs
    vlabs = vdict.valuelabels
    while rectyp == 3
        dictf, dictui, inds = readlabelset(io, bytecomp, bias)
        if bytecomp && length(dictui) == length(dictf)  ## switch to compressed bytes
            for j in inds
                typs[j] = UInt8
                vlabs[nms[j]] = dictui
            end
        else
            for j in inds
                vlabs[nms[j]] = dictf
            end
        end
        rectyp = read(io, Int32)
    end
    return rectyp
end
