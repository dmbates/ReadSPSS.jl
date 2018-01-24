module ReadSPSS

using Compat
using Compat.Mmap, Missings, CategoricalArrays

export SPSSDataFrame, read_sav

include("types.jl")

end # module
