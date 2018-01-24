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
    name::String
    vtype::DataType
    width::Int
    label::String
    missing_values::Vector{Float64}
    print::Int32
    write::Int32
end
const blankname = repeat([0x00], inner=8)

function SPSSvariablerecord(io::IO)
    pos = position(io) - 4
    vals = read(io, Int32, 5)
    vtype = String
    width = vals[1]
    if width == 0
        vtype = Float64
        width = 8
    end
    chars = read(io, 8)
    if (chars == blankname)
        println()
        error("blank name encountered at position $pos")
    end
    name = strip(String(chars))
    label = ""
    if Bool(vals[2])
        label_len = read(io, Int32)
        label = strip(String(read(io, label_len)))
        if (rem = mod(label_len, 4)) ≠ 0
            skip(io, 4 - rem)
        end
    end
    SPSSvariablerecord(name, vtype, width, label, read(io, Float64, vals[3]), vals[4], vals[5])
end

function readlabels(io::IO)
    n = read(io, Int32)
    dict = sizehint!(Dict{Float64, String}(), n)
    for i = 1:n
        k = read(io, Float64)
        nchar = read(io, Int8)
        dict[k] = String(read(io, nchar))
        extras = rem(nchar + 1, 8)
        if extras ≠ 0
            skip(io, 8 - extras)
        end
    end
    read(io, Int32) == 4 || throw(ArgumentError("Malformed stream"))
    dict, read(io, Int32, read(io, Int32))
end

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
        infodict[:longvarnames] = split(String(contents), '\t')
    elseif subtyp == 14
        infodict[:stringlengths] = contents
    elseif subtyp == 16
        infodict[:ncases64] = reinterpret(Int64, contents)
    elseif subtyp == 17
        infodict[:datafileattributes] = String(contents)
    elseif subtyp == 18
        infodict[:variableattributes] = String(contents)
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
struct SPSSDataFrame
    header::SPSSheader
    vars::Vector{SPSSvariablerecord}
    labels::Vector{Dict{Float64,String}}
    labelassign::Vector{Vector{Int32}}
    info::Dict{Symbol,Any}
end

function read_sav(io::IO)
    head = SPSSheader(io)
    vars = SPSSvariablerecord[]
    labels = Dict{Float64,String}[]
    labelassign = Vector{Int32}[]
    info = Dict{Symbol,Any}()
    rectyp = read(io, Int32)
    while rectyp in 2:7
        if rectyp == 2
            push!(vars, SPSSvariablerecord(io))
        elseif rectyp == 3
            dict, vec = readlabels(io)
            push!(labels, dict)
            push!(labelassign, vec)
        elseif rectyp == 7
            readinfo(io, info)
        else
            println("unknown type: ", rectyp)
        end
        rectyp = read(io, Int32)
    end
    if rectyp == 999
        skip(io, 4)
    else
        println("rectype $rectype encountered")
    end
    SPSSDataFrame(head, vars, labels, labelassign, info)
end
