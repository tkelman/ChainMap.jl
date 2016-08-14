bitnot = ~

e = :(vcat(~a, ~a, ~[3, 4], ~(b...) ))
is_dots(e) = false
is_dots(e::Expr) = e.head == :...

replace_key(e) =
    if is_dots(e)
        Expr(:..., gensym() )
    else
        gensym()
    end

function add_key!(d, key)
    if !(haskey(d, key))
        d[key] = replace_key(key)
    end
    d[key]
end

map_expression(f, e::Expr) = Expr(e.head, map(f, e.args)...)

replace_record!(e, d) = e
replace_record!(e::Expr, d) =
    MacroTools.@match e begin
        ~(key_) => add_key!(d, key)
        e_ => map_expression(e -> replace_record!(e, d), e)
    end

function replace_record(e::Expr)
    d = Dict()
    e_replace = replace_record!(e, d)
    (e_replace, d)
end

export unweave
"""
    @unweave e

Interprets `e` as a function with its positional arguments wrapped in tildas and
interwoven into it.

Will return a [`LazyCall`](@ref) object containing both an anonymous function
and its arguments. You can also weave in *only one* splatted argument. Make
multi-line functions by wrapping in a begin block. To use `~` as a
function, use the alias [`bitnot`](@ref).

# Examples

```julia
a = [1, 2]
b = ( [5, 6], [7, 8] )

fancy = @chain begin
    a
    begin @unweave vcat(~_, ~_, ~[3, 4], ~(b...) ) end
    run(map)
end

boring = map((a, c, b...) -> vcat(a, a, c, b...), a, [3, 4], b...)

@test fancy == boring

# No arguments marked with tildas detected
@test_throws ErrorException ChainMap.unweave(:( 1 + 1 ))
# Cannot include more than one splatted argument
@test_throws ErrorException ChainMap.unweave(:( ~(a...) + ~(b...) ))
```
"""
function unweave(e::Expr)
    e_replace, d = replace_record(e)

    if length(d) == 0
        error("No arguments marked with tildas detected")
    end

    dotted = filter((k, v) -> MacroTools.isexpr(k, :...), d)
    undotted = filter((k, v) -> !(MacroTools.isexpr(k, :...)), d)

    if length(dotted) > 1
        error("Cannot include more than one splatted argument")
    end

    anonymous_arguments = Expr(:tuple, values(undotted)..., values(dotted)...)
    over_arguments = (keys(undotted)..., keys(dotted)...)

    anonymous_function = :($anonymous_arguments -> $e_replace)
    collected_arguments = :(ChainMap.collect_arguments($(over_arguments...)))

    :(ChainMap.LazyCall($collected_arguments, $anonymous_function))
end

export bitnot
"""
    bitnot

Alias for `~` for use within [`@unweave`](@ref)

# Examples
```julia
@test bitnot(1) == ~1
```
"""
bitnot = ~
