double_match(e, head1, head2) =
    MacroTools.isexpr(e, head1) &&
    length(e.args) > 0 &&
    @chain e.args[1] MacroTools.isexpr(head2)


function replace_key(e)
    replace_symbol = gensym()
    if @chain e double_match(:parameters, :...)
        @chain replace_symbol Expr(:..., _)
    elseif @chain e MacroTools.isexpr(:...)
        @chain replace_symbol Expr(:..., _)
    else
        replace_symbol
    end
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

function move_to_last(o::DataStructures.OrderedDict, f::Function)
    to_last = @chain f filter(o)
    if length(to_last) > 1
        error("A maximum of one splatted positional and one splatted keyword argument allowed")
    end
    @chain (k, v) -> !f(k, v) filter(o) merge(to_last)
end

move_to_last(d::Dict, f::Function) =
    @chain d DataStructures.OrderedDict() move_to_last(f)

reorder_arguments(d) = @chain begin
    d
    move_to_last( (k, v) -> @chain k MacroTools.isexpr(:...) )
    move_to_last( (k, v) -> @chain k double_match(:parameters, :...) )
end

lazy_anonymous(arguments, f) = :($arguments -> $f)
lazy_LazyCall(arguments, f) = :(LazyCall($arguments, $f))
lazy_collect_arguments(es) = :(collect_arguments($(es...)))

export unweave
"""
    @unweave e

Interprets `e` as a function with its positional arguments wrapped in tildas and
interwoven into it.

Will return a [`LazyCall`](@ref) object containing both an anonymous function
and its arguments. Keyword arguments can be woven in. No more than one splatted
positional argument can be woven in. No more than one splatted keyword can be
woven in provided there is a `;` visible both inside and outside the tilda. Make
multi-line functions by wrapping in a begin block. To use `~` as a function, use
the alias [`bitnot`](@ref).

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

keyword_test(; keyword_arguments...) = keyword_arguments

a = keyword_test(a = 1, b = 3)
e = :(keyword_test(~(b = 2); ~(;a...)))
unweave_keyword_test = @chain
    @unweave keyword_test(~(b = 2); ~(;a...))
    run
end

@test unweave_keyword_test == keyword_test(b = 2; a... )

# No arguments marked with tildas detected
@test_throws ErrorException ChainMap.unweave(:( 1 + 1 ))
# Cannot include more than one splatted argument
@test_throws ErrorException ChainMap.unweave(:( ~(a...) + ~(b...) ))
```
"""
function unweave(e::Expr)
    e_replace, d = @chain e replace_record

    if length(d) == 0
        error("No arguments marked with tildas detected")
    end

    d_reorder = @chain d reorder_arguments

    anonymous_function =
      @chain d_reorder values Expr(:tuple, _...) lazy_anonymous(e_replace)

    @chain begin
        d_reorder
        keys
        lazy_collect_arguments
        lazy_LazyCall(anonymous_function)
    end
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
