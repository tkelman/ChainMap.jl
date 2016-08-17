double_match(e, head1, head2) =
    MacroTools.isexpr(e, head1) &&
    length(e.args) > 0 &&
    @chain e.args[1] MacroTools.isexpr(head2)


function replace_key(e)
    replace_symbol = gensym()
    if @chain e double_match(:parameters, :...)
        @chain replace_symbol Expr(:..., _) Expr(:parameters, _)
    elseif @chain e MacroTools.isexpr(:...)
        @chain replace_symbol Expr(:..., _)
    else
        replace_symbol
    end
end

unparameterize(e) = e
unparameterize(e::Expr) =
    if e.head == :parameters && length(e.args) == 1
        e.args[1]
    else
        e
    end

function add_key!(d, key)
    if @chain d haskey(key) !
        d[key] = replace_key(key)
    end
    unparameterize( d[key] )
end

map_expression(f, e::Expr) = @chain begin
    e.args
    map(f, _)
    Expr(e.head, _...)
end

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

negate(f) = (k, v) -> !f(k, v)

function dots_to_back(o::DataStructures.OrderedDict)
    is_dots = (k, v) -> @chain k MacroTools.isexpr(:...)
    to_back = @chain o filter(is_dots, _)
    if length(to_back) > 1
        error("Can splat no more than one positional argument")
    end
    @chain o filter(negate(is_dots), _) merge(to_back)
end

function parameters_to_front(o::DataStructures.OrderedDict)
    is_parameters = (k, v) -> @chain k double_match(:parameters, :...)
    to_front = @chain o filter(is_parameters, _)
    if length(to_front) > 1
        error("Can splat no more than one keyword argument")
    end
    @chain o filter(negate(is_parameters), _) merge(to_front, _)
end

export unweave
"""
    @unweave e

Interprets `e` as a function with its positional arguments wrapped in tildas and
interwoven into it.

Will return a [`LazyCall`](@ref) object containing both an anonymous function
and its arguments. No more than one splatted positional argument can be woven
in. No more than one splatted keyword argument can be woven in provided there is
a `;` visible both inside and outside the tilda. Make multi-line functions by
wrapping in a begin block. To use `~` as a function, use the alias
[`bitnot`](@ref).

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

a = keyword_test(a = 1, b = 2)

unweave_keyword_test = @chain begin
    @unweave keyword_test(; c = 3, ~(; a...))
    run
end

@test unweave_keyword_test == keyword_test(c = 3; a... )

# Can splat no more than one positional argument
@test_throws ErrorException ChainMap.unweave(:( ~(a...) + ~(b...) ))
# Can splat no more than one keyword argument
@test_throws ErrorException ChainMap.unweave(:( ~(;a...) + ~(;b...) ))
```
"""
function unweave(e::Expr)
    e_replace, d = @chain e replace_record

    d_reorder = o = @chain begin
        d
        DataStructures.OrderedDict()
        parameters_to_front
        dots_to_back
    end

    anonymous_function = @chain begin
        d_reorder
        values
        Expr(:tuple, _...)
        Expr(:->, _, e_replace)
    end

    @chain begin
        d_reorder
        keys
        Expr(:call, :collect_arguments, _...)
        Expr(:call, :LazyCall, _, anonymous_function)
    end
end

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
unweave(insert_this, into_that) = @chain begin
    insert_this
    Expr(:call, :~, _)
    chain(into_that)
    unweave
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

@nonstandard unweave
export @unweave
