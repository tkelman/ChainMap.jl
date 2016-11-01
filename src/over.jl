export @over

"""
    double_match(e, first, second)

Test whether `e` calls `first`, and the first argument calls `second`

#Examples
```julia
e = Expr(:parameters, Expr(:..., :a) )
first = :parameters
second = :...
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
e = Expr(:..., :a)
```
"""
replace_key(e, symbol = gensym() ) = @chain begin
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
e = Expr(:parameters, :a)
e = :b
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

e = Expr(:parameters, Expr(:..., :d) )
```
"""
add_key!(d, e, symbol = gensym() ) = @chain begin
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
```
"""
replace_record!(e, d) =
    MacroTools.@match e begin
        ~(e_) => add_key!(d, e)
        e_ => map_expression(e, e -> replace_record!(e, d) )
    end

"""
# Examples
```julia
f = x -> x == :a
```
"""
negate(f) = (args...; kwargs...) -> !(f(args...; kwargs...))

dots_to_back(o::DataStructures.OrderedDict) = @chain begin
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

parameters_to_front(o::DataStructures.OrderedDict) = @chain begin
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

```julia
e = :(~_ + 1)
```
"""
split_anonymous(e::Expr) = @chain begin
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

"""
```julia
e = :( vcat(~a, ~b) )
f = :broadcast
```
"""
over(e::Expr, f::Symbol = :broadcast) = begin
    anonymous_function, anonymous_arguments = split_anonymous(e)
    Expr(:call, f, anonymous_function, anonymous_arguments...)
end

"""
```julia
e = :( vcat(~a, ~b) )
f = :(broadcast_tuple(as_tuple = true) )
```
"""
over(e::Expr, f::Expr) = begin
    function_test = MacroTools.@capture f function_call_(arguments__)

    if !(function_test)
        error("`f` must be a call")
    end

    anonymous_function, anonymous_arguments = split_anonymous(e)

    Expr(:call, function_call, anonymous_function,
         arguments..., anonymous_arguments...)

end

"""
    @over(e::Expr, f = :broadcast)

Split `e` into an anonymous function and arguments, then insert the function
as the first argument to `f` and the woven arguments at the end of the arguments
of `f`.


Interprets `e` as a function with its positional arguments wrapped in tildas and
interwoven into it. No more than one splatted positional argument can be woven
in. No more than one splatted keyword argument can be woven in provided there is
a `;` visible both inside and outside the tilda. To use `~` as a function, make
an alias.

# Examples
```julia
a = [1, 2]
b = [3, 4]

@test broadcast( (a, b) -> vcat(a, b), a, b) ==
    @over vcat(~a, ~b)

broadcast_tuple(args...; as_tuple = false) =
    if as_tuple
        (broadcast(args...)...)
    else
        broadcast(args...)
    end

a = [1, 2]
b = [3, 4]

@test broadcast_tuple( (a, b) -> vcat(a, b), a, b, as_tuple = true) ==
    @over vcat(~a, ~b) broadcast_tuple(as_tuple = true)

A = [1, 2]
B = ( [5, 6], [7, 8] )
@test vcat.(A, [3, 4], B...) ==
    @over vcat(~A, ~[3, 4], ~(B...) )

# Must include at least one woven argument
@test_throws ErrorException ChainMap.over(:(a + b) )
# Can splat no more than one positional argument
@test_throws ErrorException ChainMap.over(:( ~(a...) + ~(b...) ) )
# Can splat no more than one keyword argument
@test_throws ErrorException ChainMap.over(:( ~(;a...) + ~(;b...) ) )
# `f` must be a call
@test_throws ErrorException ChainMap.over(:(~_ + 1), :(import ChainMap) )
```
"""
macro over(e...)
    esc(over(e...))
end
