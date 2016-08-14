bitnot = ~

replace_key(e) =
    if @chain e MacroTools.isexpr(:...)
        @chain gensym() Expr(:..., _)
    else
        gensym()
    end

function add_key!(d, key)
    if @chain d haskey(key) !
        d[key] = replace_key(key)
    end
    d[key]
end

map_expression(f, e::Expr) =
    @chain e.args map(f, _) Expr(e.head, _...)

replace_record!(e, d) = e
replace_record!(e::Expr, d) =
    MacroTools.@match e begin
        ~(key_) => @chain d add_key!(key)
        e_ => @chain e -> replace_record!(e, d) map_expression(e)
    end

function replace_record(e::Expr)
    d = Dict()
    e_replace = @chain e replace_record!(d)
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
A = [1, 2]
B = ( [5, 6], [7, 8] )

unweave_test = @chain begin
    @unweave vcat(~A, ~[3, 4], ~(B...) )
    run(map)
end

@test unweave_test ==
      map((a, c, b...) -> vcat(a, c, b...), A, [3, 4], B...)

# No arguments marked with tildas detected
@test_throws ErrorException ChainMap.unweave(:( 1 + 1 ))
# Cannot include more than one splatted argument
@test_throws ErrorException ChainMap.unweave(:( ~(a...) + ~(b...) ))

e = Expr(:parameters, Expr(:..., :a))
e = Expr(:..., :a)
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

tilda(e) = :(~($e))

"""
     @unweave(insert_this, into_that)

Mark `insert_this` with a tilda, [`chain`](@ref) it `into_that`, and `unweave`
the result.

# Examples
```julia
A = [1, 2]
B = ( [5, 6], [7, 8] )

unweave_test = @chain begin
    A
    @unweave vcat(~[3, 4], ~(B...) )
    run(map)
end

@test unweave_test ==
      map((a, c, b...) -> vcat(a, c, b...), A, [3, 4], B...)
```
"""
unweave(insert_this, into_that) =
     @chain insert_this tilda chain(into_that) unweave


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

@nonstandard unweave
export @unweave
