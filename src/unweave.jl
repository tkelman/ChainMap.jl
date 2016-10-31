@chain begin

"""
# Examples
```julia
f = x -> x == :a
@test ChainMap.negate(f)(:b)
```
"""
negate(f) = (args...; kwargs...) -> !(f(args...; kwargs...))

function dots_to_back(o::DataStructures.OrderedDict)
    is_dots = (k, v) -> MacroTools.isexpr(k, :...)
    to_back = filter(is_dots, o)
    if length(to_back) > 1
        error("Can splat no more than one positional argument")
    end
    begin
        o
        filter(negate(is_dots), _)
        merge(_, to_back)
    end
end

function parameters_to_front(o::DataStructures.OrderedDict)
    is_parameters = (k, v) -> double_match(k, :parameters, :...)
    to_front = filter(is_parameters, o)
    if length(to_front) > 1
        error("Can splat no more than one keyword argument")
    end
    begin
        o
        filter(negate(is_parameters), _)
        merge(to_front, _)
    end
end

"""
    split_anonymous(e::Expr)

Return the component anonymous function and arguments for [`unweave`](@ref).

```julia
e = :(~_ + 1)
ChainMap.split_anonymous(e)
```
"""
function split_anonymous(e::Expr)
    d = Dict()
    e_replace = replace_record!(e, d)

    if length(d) == 0
        error("Must include at least one woven argument")
    end

    d_reorder = begin
        d
        DataStructures.OrderedDict(_)
        parameters_to_front
        dots_to_back
    end

    anonymous_function = begin
        d_reorder
        values
        Expr(:tuple, _...)
        Expr(:->, _, e_replace)
    end

    (anonymous_function, keys(d_reorder))
end

export unweave
"""
    @unweave e::Expr

Interprets `e` as a function with its positional arguments wrapped in tildas and
interwoven into it.

Will return a [`LazyCall`](@ref) object containing both an anonymous function
and its arguments. No more than one splatted positional argument can be woven
in. No more than one splatted keyword argument can be woven in provided there is
a `;` visible both inside and outside the tilda. Make multi-line functions by
wrapping in a begin block. To use `~` as a function, use the alias
[`bitnot`](@ref). If there are no woven arguments in `e`, return `e`.

# Examples

```julia
A = [1, 2]
B = ( [5, 6], [7, 8] )

unweave_test = @chain begin
    @unweave vcat(~A, ~[3, 4], ~(B...) )
    run(_, map)
end

@test unweave_test ==
      map((a, c, b...) -> vcat(a, c, b...), A, [3, 4], B...)

keyword_test(; keyword_arguments...) = keyword_arguments

a = keyword_test(a = 1, b = 2)

unweave_keyword_test = @chain begin
    @unweave keyword_test(c = 3; ~(a...))
    run
end

@test unweave_keyword_test == keyword_test(c = 3; a... )

# Must include at least one woven argument
@test_throws ErrorException unweave(:(a + b))

# Can splat no more than one positional argument
@test_throws ErrorException unweave(:( ~(a...) + ~(b...) ))

# Can splat no more than one keyword argument
@test_throws ErrorException unweave(:( ~(;a...) + ~(;b...) ))
```
"""
function unweave(e::Expr)
    anonymous_function, arguments = split_anonymous(e)

    begin
        arguments
        Expr(:call, :collect_arguments, _...)
        Expr(:call, :LazyCall, _, anonymous_function)
    end
end
@nonstandard unweave
export @unweave


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

end
