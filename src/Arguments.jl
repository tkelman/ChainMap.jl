import Base.==
import Base.run
import Base.copy
import Base.push!
import Base.unshift!

export Arguments

"""
A type that can be used to store arguments. Will store positional and keyword
arguments for later use.
"""
type Arguments
  positional::Tuple
  keyword::Vector{Any}
end

"""
    Arguments(positional...; keyword...)

Construct an Arguments type. Will store positional and keyword arguments for
later use.
"""
function Arguments(positional...; keyword...)
  Arguments(positional, keyword )
end

copy(a::Arguments) = Arguments(a.positional...; a.keyword...)

"""
    push!(arguments::Arguments, positional...; keyword...)

Add positional and keyword arguments to an already existing arguments type.
Arguments are added at the end.
"""
function push!(a::Arguments, positional...; keyword...)
  a.positional = (a.positional..., positional...)
  @c a.keyword append!(keyword)
  a
end

"""
    unshift!(arguments::Arguments, positional...; keyword...)

Add positional and keyword arguments to an already existing arguments type.
Arguments are added at the start.
"""
function unshift!(a::Arguments, positional...; keyword...)
  a.positional = (positional..., a.positional...)
  @c a.keyword append!(keyword)
  a
end

"""
    ==(a::Arguments, b::Arguments)

Test whether the contents and order of positional arguments is the same, and
that the same keyword arguments are present ignoring order.
"""
==(a::Arguments, b::Arguments) =
  (a.positional == b.positional) &
  @c a.keyword symdiff(b.keyword) length (_ == 0)

"""
     run(a::Arguments, f)

Call `f` on the arguments in `a`
"""
run(a::Arguments, f) = f(a.positional...; a.keyword...)
