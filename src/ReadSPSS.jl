module ReadSPSS

using Compat
using Compat.Mmap, Missings, CategoricalArrays

export SPSSDataFrame, read_sav

include("headerrecord.jl")
include("variablerecord.jl")
include("valuelabels.jl")
include("documentrecord.jl")
include("extensionrecord.jl")
include("bytecodedata.jl")
include("readers.jl")

end # module
