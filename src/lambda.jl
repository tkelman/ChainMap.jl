"""
    lambda(x)

Standard evaluation version of `@l`.
"""
lambda(x) = :(_ -> $x)

"""
    @l x

An anonymous function is constructed, with `_` as an input varible.

`@l -(2, \_)` will return `\_ -> -(2, \_)`
"""
macro l(x)
  @c x lambda esc
end
