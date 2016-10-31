export over, @over

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
ChainMap.replace_record!(e, d)
@test :a in keys(d)
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
@test ChainMap.negate(f)(:b)
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
ChainMap.split_anonymous(e)
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
e = :( vcat(~a, ~b) )
f = :broadcast
over(e, f)

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

e = :( vcat(~a, ~b) )
f = :(broadcast_tuple(as_tuple = true) )
over(e, f)

a = [1, 2]
b = [3, 4]

@test broadcast_tuple( (a, b) -> vcat(a, b), a, b, as_tuple = true) ==
@over vcat(~a, ~b) broadcast_tuple(as_tuple = true)

# `f` must be a call
@test_throws ErrorException over(:(~_ + 1), :(import ChainMap) )
```
"""
over(e::Expr, f::Symbol = :broadcast) = begin
    anonymous_function, anonymous_arguments = split_anonymous(e)
    Expr(:call, f, anonymous_function, anonymous_arguments...)
end

over(e::Expr, f::Expr) = begin
    function_test = MacroTools.@capture f function_call_(arguments__)

    if !(function_test)
        error("`f` must be a call")
    end

    anonymous_function, anonymous_arguments = split_anonymous(e)

    Expr(:call, function_call, anonymous_function,
         arguments..., anonymous_arguments...)

end

@nonstandard over