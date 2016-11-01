export @with

with(e) = MacroTools.@match e begin
    ^(e_) => e
    :(e_) => Expr(:ref, :_, Meta.quot(e) )
    a_.b_ => Expr(:., with(a), Meta.quot(b) )
    e_ => map_expression(e, with)
end

"""
    @with(e)

Extract any symbols in `e`, such as `:a`, from `_`, e.g.
`_[:a]`.

Anything wrapped in `^`, such as `^(escaped)`, gets passed through untouched.

### Examples
```julia
a = 1
_ = Dict(:a => 2)

@test Dict("a" => _[:a] + a, "b" => :b) ==
   @with Dict("a" => :a + a, "b" => ^(:b))
```
"""
macro with(e...)
    esc(with(e...) )
end
