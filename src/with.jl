export with, @with

"""
    map_expression(e, f)

If `e` is an expression, map `f` over the arguments in `e`.
"""
map_expression(e, f) = e
map_expression(e::Expr, f) = Expr(f(e.head), map(f, e.args)...)

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
with(e) = MacroTools.@match e begin
    ^(e_) => e
    :(e_) => Expr(:ref, :_, Meta.quot(e) )
    a_.b_ => Expr(:., with(a), Meta.quot(b) )
    e_ => map_expression(e, with)
end
@nonstandard with
