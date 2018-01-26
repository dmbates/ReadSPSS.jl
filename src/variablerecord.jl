const buf8bytes = zeros(UInt8, 8)
const buf5int32 = zeros(Int32, 5)

function readvariablerecord!(io::IO, nms::Vector{Symbol}, typs::Vector{DataType},
                            widths::Vector{Int32}, labels::Vector{String},
                            msngvals::Vector{Vector{Float64}}, readwrite::Vector{Int32})
    v = read!(io, buf5int32)
    width = v[1]
    width < 0 && return
    push!(typs, iszero(width) ? Float64 : String)
    push!(widths, iszero(width) ? 8 : width)
    read!(io, buf8bytes)
    if 0x00 in buf8bytes
        error("got name $buf8bytes at position $(length(typs))")
    else
        push!(nms, Symbol(strip(String(buf8bytes))))
    end
    label = ""
    if Bool(v[2])
        label_len = read(io, Int32)
        label = strip(String(read(io, label_len)))
        if (rem = mod(label_len, 4)) ≠ 0
            skip(io, 4 - rem)
        end
    end
    push!(labels, label)
    push!(msngvals, read!(io, Vector{Float64}(v[3])))
    push!(readwrite, v[4])
    push!(readwrite, v[5])
end

struct VariableDictionary
    nms::Vector{Symbol}
    typs::Vector{DataType}
    widths::Vector{Int32}
    labels::Vector{String}
    valuelabels::Dict{Symbol,Dict}
    msngvals::Vector{Vector{Float64}}

    readwritefmt::Matrix{Int32}
end

function readvariabledictionary(io::IO, casesz)
    nms = sizehint!(Symbol[], casesz)
    typs = sizehint!(DataType[], casesz)
    wdths = sizehint!(Int32[], casesz)
    labels = sizehint!(String[], casesz)
    msngvals = sizehint!(Vector{Float64}[], casesz)
    rdwrt = sizehint!(Int32[], 2 *casesz)
    rectyp = Int32(2)
    while rectyp == 2
        readvariablerecord!(io, nms, typs, wdths, labels, msngvals, rdwrt)
        rectyp = read(io, Int32)
    end
    if all(isempty, msngvals)
        msngvals = Vector{Float64}[]
    end
    vdicts = [Dict{T,String}() for T in typs]
    rdwrt = reshape(rdwrt, (2, length(typs)))
    rectyp, VariableDictionary(nms, typs, wdths, labels, Dict{Symbol,Dict}(), msngvals, rdwrt)
end
