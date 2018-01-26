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
    if rectyp == 3   # read value labels, if any
        rectyp = readvaluelabels!(io, vdict, comp == 1, bias)
    end
    if rectyp == 6
        rectyp = readdocumentrecord(io)
    end
    if rectyp == 7
        rectyp, infodict = readextensionrecords(io, vdict)
    end
    if rectyp == 999
        skip(io, 4)
    else
        println("rectype $rectyp encountered")
    end
    SPSSDataFrame(vdict, Vector{Any}[], producer, cdate, ctime, flabel), infodict
end
