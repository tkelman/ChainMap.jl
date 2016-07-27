module ChainMap
import MacroTools

include("buildfunctions.jl")
include("chain.jl")
include("over.jl")
include("Arguments.jl")
include("generate.jl")
include("doc.jl")

export @safe, @allsafe, @chain, @over, @lambda, @nonstandard, bitnot, push, @multiblock, unshift, remove_suffix

end
