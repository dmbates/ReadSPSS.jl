@enum FPtyp  IEEE=1 IBM DEC
@enum ENDIAN BIG=1 LITTLE

expectedblksz(typ::Int32) = (typ in [4, 16]) ? 8 : ((typ in [3, 11]) ? 4 : 1)

function readinfo(io::IO, infodict)
    subtyp, blksz, nblk = read(io, Int32, 3)
    blksz == expectedblksz(subtyp) || error("subtyp $subtyp gave blksz $blksz")
    contents = read(io, blksz * nblk)
    if subtyp == 3
        v = reinterpret(Int32, contents)
        infodict[:version] = VersionNumber(v[1], v[2], v[3])
        infodict[:FPrep] = FPtyp(v[5])
        infodict[:endian] = ENDIAN(v[7])
        infodict[:charactercode] = v[8]
    elseif subtyp == 4
        v = reinterpret(Float64, contents)
        infodict[:sysmiss] = v[1]
        infodict[:highest] = v[2]
        infodict[:lowest] = v[3]
    elseif subtyp == 10
        infodict[:product] = String(contents)
    elseif subtyp == 11
        infodict[:display] = reinterpret(Int32, contents)
    elseif subtyp == 13
        infodict[:longvarnames] = 
            Dict{Symbol,Symbol}(map(x -> Symbol.(x),
                               filter(x -> length(x) == 2 && x[1] ≠ x[2],
                               split.(split(String(contents), '\t'), '='))))
    elseif subtyp == 14
        infodict[:stringlengths] = contents
    elseif subtyp == 16
        infodict[:ncases64] = reinterpret(Int64, contents)
    elseif subtyp == 17
        infodict[:datafileattributes] = String(contents)
    elseif subtyp == 18
        infodict[:variableattributes] = Dict{Symbol,String}(
            map(x -> (Symbol(x[1]), x[2]), split.(split(String(contents), '/'), ':')))
    elseif subtyp == 20
        infodict[:encoding] = String(contents)
    elseif subtyp == 21
        infodict[:longstringvalue] = contents
    elseif subtyp == 22
        infodict[:longstringmissing] = contents
    else
        error("unknown info subtype: ", subtyp)
    end
end
