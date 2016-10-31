export with, @with

"""
    map_expression(e, f)

If `e` is an expression, map `f` over the arguments in `e`.
"""
map_expression(e, f) = e
map_expression(e::Expr, f) = Expr(f(e.head), map(f, e.args)...)

"""
    @with(e, associative = \_)

Extract any symbols in `e`, such as `:a`, from `associative`, e.g.
`associative[:a]`.

Anything wrapped in `^`, such as `^(escaped)`, gets passed through untouched.

### Examples
```julia
a = 1
_ = Dict(:a => 2)

@test Dict("a" => _[:a] + a, "b" => :b) ==
   @with Dict("a" => :a + a, "b" => ^(:b))
```
"""
with(e, associative = :_) = MacroTools.@match e begin
    ^(e_) => e
    :(e_) => Expr(:ref, associative, Meta.quot(e) )
    a_.b_ => Expr(:., with(a, associative), Meta.quot(b) )
    e_ => map_expression(e, e -> with(e, associative) )
end
@nonstandard with
