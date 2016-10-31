export over
"""
    @over(e::Expr, f::Symbol = broadcast)

[`unweave`](@ref) `e` then run `f` on the component parts, anonymous function
first.

# Examples
```julia
e = :( vcat(~a, ~b) )
f = :broadcast
over(e, f)

a = [1, 2]
b = [3, 4]

@test broadcast( (a, b) -> vcat(a, b), a, b) ==
    @over vcat(~a, ~b)
```
"""
function over(e::Expr, f::Symbol = :broadcast)

    anonymous_function, anonymous_arguments = split_anonymous(e)

    Expr(:call, f, anonymous_function, anonymous_arguments...)

end

"""
    @over e::Expr f::Expr

[`unweave`](@ref) `e` then insert the function as the first argument to `f` and
the woven arguments at the end of the arguments of `f`.

`f` must be a call.

# Examples
```julia
broadcast_tuple(args...; as_tuple = false) =
    if as_tuple
        (broadcast(args...)...)
    else
        broadcast(args...)
    end

e = :( vcat(~a, ~b) )
f = :(broadcast_tuple(as_tuple = true) )

over(e, f)

a = [1, 2]
b = [3, 4]

result = @over ~a + ~b broadcast_tuple(as_tuple = true)

@test broadcast_tuple( (a, b) -> vcat(a, b), a, b, as_tuple = true) ==
    @over vcat(~a, ~b) broadcast_tuple(as_tuple = true)

# `f` must be a call
@test_throws ErrorException over(:(~_ + 1), :(import ChainMap) )
```
"""
function over(e::Expr, f::Expr)

    function_test = MacroTools.@capture f function_call_(arguments__)

    if !(function_test)
        error("`f` must be a call")
    end

    anonymous_function, anonymous_arguments = split_anonymous(e)

    Expr(:call, function_call, anonymous_function,
         arguments..., anonymous_arguments...)

end

@nonstandard over
export @over
