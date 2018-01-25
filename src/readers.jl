struct SPSSDataFrame
    header::SPSSheader
    vars::Vector{SPSSvariablerecord}
    labelsf::Vector{Dict{Float64,String}}
    labelsui::Vector{Dict{UInt8,String}}
    labelassign::Vector{Vector{Int32}}
    info::Dict{Symbol,Any}
end

function read_sav(io::IO)
    head = readheader(io)
    vars = SPSSvariablerecord[]
    labelsf = Dict{Float64,String}[]
    labelsui = Dict{UInt8,String}[]
    labelassign = Vector{Int32}[]
    info = Dict{Symbol,Any}()
    rectyp = read(io, Int32)
    while rectyp in 2:7
        if rectyp == 2
            readvariablerecord(io, vars)
        elseif rectyp == 3
            dictf, dictui, vec = readlabels(io)
            push!(labelsf, dictf)
            push!(labelsui, dictui)
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
        println("rectype $rectyp encountered")
    end
    SPSSDataFrame(head, vars, labelsf, labelsui, labelassign, info)
    
end
