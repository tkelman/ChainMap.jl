export with, @with

@chain begin

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

"""
    double_match(e, first, second)

Test whether `e` calls `first`, and the first argument calls `second`

#Examples
```julia
e = Expr(:parameters, Expr(:..., :a) )
first = :parameters
second = :...

@test ChainMap.double_match(e, first, second)
@test !ChainMap.double_match(:b, :parameters, :...)
```
"""
double_match(e, first, second) =
    MacroTools.isexpr(e, first) &&
    length(e.args) > 0 &&
    MacroTools.isexpr(e.args[1], second)

"""
    replace_key(e, symbol = gensym())

Replace `e` with `gensym()`.

`e` can be wrapped in `...` or `...` and `;`.

#Examples
```julia
e = Expr(:parameters, Expr(:..., :a) )
@test ChainMap.replace_key(e, :b) == Expr(:parameters, Expr(:..., :b) )

e = Expr(:..., :a)
@test ChainMap.replace_key(e, :b) == Expr(:..., :b)

@test ChainMap.replace_key(:a, :b) == :b
```
"""
replace_key(e, symbol = gensym() ) = begin
    if double_match(e, :parameters, :...)
        begin
            symbol
            Expr(:..., _)
            Expr(:parameters, _)
        end
    elseif MacroTools.isexpr(e, :...)
        Expr(:..., symbol)
    else
        symbol
    end
end

"""
    unparameterize(e)

Remove `;` from `e`.

#Examples
```julia
a = Expr(:..., :a)

@test ChainMap.unparameterize(Expr(:parameters, a) ) == a

@test ChainMap.unparameterize(:b) == :b
```
"""
unparameterize(e) =
     if MacroTools.isexpr(e, :parameters) && length(e.args) == 1
         e.args[1]
     else
         e
     end

"""
    add_key!(d, e, symbol = gensym() )

'replace_key' of `e` and add `e` mapped to `symbol` to `d`. Return `e`
unparameterized.

# Examples
```julia
e = :a
symbol = :z
d = Dict(:a => :b, :(a + 1) => :(b + 1))

ChainMap.add_key!(d, e, symbol)
@test d[:a] == :b

ChainMap.add_key!(d, :c, symbol)
@test d[:c] == :z

e = Expr(:parameters, Expr(:..., :d) )
@test ChainMap.add_key!(d, e, symbol) == Expr(:..., :z)
@test d[e] == Expr(:parameters, Expr(:..., :z) )
```
"""
add_key!(d, e, symbol = gensym() ) = begin
    if begin
        d
        haskey(_, e)
        !
    end
        d[e] = replace_key(e, symbol)
    end
    unparameterize( d[e] )
end

"""
# Examples
```julia
d = Dict()
e = :( 1 + ~(a))
ChainMap.replace_record!(e, d)
@test :a in keys(d)
```
"""
replace_record!(e, d) =
    MacroTools.@match e begin
        ~(e_) => add_key!(d, e)
        e_ => map_expression(e, e -> replace_record!(e, d) )
    end

end
