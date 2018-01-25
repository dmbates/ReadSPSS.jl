module ReadSPSS

using Compat
using Compat.Mmap, Missings, CategoricalArrays

export SPSSDataFrame, read_sav

include("headerrecord.jl")
include("variablerecord.jl")
include("valuelabels.jl")
include("inforecord.jl")
include("readers.jl")

end # module
