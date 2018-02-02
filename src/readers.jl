struct SPSSDataFrame
    vars::VariableDictionary
    data::Vector{Any}
    producer::String
    creation_date::String
    creation_time::String
    label::String
end

function read_sav(io::IO)
    comp, bias, casesz, ncases, producer, cdate, ctime, flabel = readheader(io)
    bias = Int(bias)
    rectyp = read(io, Int32)
    @assert rectyp == 2 "variable dictionary records should immediately follow header"
    rectyp, vdict = readvariabledictionary(io, max(casesz, 5))
    casesz = length(vdict.nms)
    ibuf = Vector{UInt8}(casesz)
    fbuf = Vector{Union{Float64,Missing}}(casesz)
    if rectyp == 3   # read value labels, if any
        rectyp = readvaluelabels!(io, vdict, comp == 1, bias)
    end
    data = [missings(T, Int64(ncases)) for T in vdict.typs]
    if rectyp == 6
        rectyp = readdocumentrecord(io)
    end
    if rectyp == 7
        rectyp, infodict = readextensionrecords(io, vdict)
    end
    if rectyp == 999
        skip(io, 4)
        if comp == 1
            typs = vdict.typs
            @inbounds for k in 1:ncases
                readbytecoderec!(io, ibuf, fbuf, bias)
                for (j,T) in enumerate(typs)
                    datj = data[j]
                    fbj = fbuf[j]
                    ibj = ibuf[j]
                    if T == String
                        if !ismissing(fbj)
                            datj[k] = strip(String(reinterpret(UInt8, [fbj])))
                        end
                    elseif T == Float64
                        datj[k] = fbj
                    elseif T == UInt8
                        datj[k] = ibj == 0xff ? missing : ibj
                    else
                        throw(ArgumentError("Unexpected type $T encountered in typs"))
                    end
                end
            end
        end
    end
    SPSSDataFrame(vdict, data, producer, cdate, ctime, flabel), infodict
end
