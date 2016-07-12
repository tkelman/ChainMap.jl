module ChainMap
import MacroTools

include("chain.jl")
include("lambda.jl")
# not sure why i can't include the exports with the file
export lambda, @l
include("over.jl")
include("safe.jl")
include("Arguments.jl")

end
