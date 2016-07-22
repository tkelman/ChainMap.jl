import Base.==
import Base.run
import Base.copy
import Base.push!
import Base.unshift!

export Arguments

type Arguments
  positional::Tuple
  keyword::Dict{Symbol, Any}
end

function Arguments(positional...; keyword...)
  Arguments(positional, Dict(keyword) )
end

copy(a::Arguments) = Arguments(a.positional, copy(a.keyword))

function push!(a::Arguments, positional...; keyword...)
  a.positional = (a.positional..., positional...)
  merge!(a.keyword, Dict(keyword))
  a
end

function unshift!(a::Arguments, positional...)
  a.positional = (positional..., a.positional...)
  a
end

==(a::Arguments, b::Arguments) =
  (a.positional == b.positional) &
  (a.keyword == b.keyword)

run(a::Arguments, f) = f(a.positional...; collect(a.keyword)...)
