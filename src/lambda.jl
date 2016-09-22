export lambda
"""
    @lambda e

Convert `e` to an anonymous function with `_` as the input variable.

# Examples
```julia
lambda_function = @lambda vcat(_, 2)
@test lambda_function(1) == vcat(1, 2)
```
"""
lambda(e) = Expr(:->, :_, e)

"""
    @lambda(f, e, v = :\_)

[`lambda`](@ref) `e` then call `f` on `e` and `v`.

# Examples
```julia
f = :map
e = :(vcat(_, 1))
lambda(f, e)

_ = [1, 2]
@test map(_ -> vcat(_, 1), _) == @lambda map vcat(_, 1)
```
"""
lambda(f, e, v = :_) = @chain begin
    e
    lambda
    Expr(:call, f, _, v)
end

"""
    @lambda(f::Expr, e, v = \_)

[`lambda`](@ref) `e` then insert `e` as as the first and `v` as the last
argument to `f`.

`f` must be a call.

# Examples
```julia
e = :(_ + 1)
f = :(NullableArrays.map(lift = true))

lambda(f, e)

_ = NullableArrays.NullableArray([1, 2], [false, true])

result = @lambda NullableArrays.broadcast(lift = true) _ + 1

@test result.values[1] == 2
@test result.isnull == [false, true]

# `f` must be a call
@test_throws ErrorException lambda(:(import ChainMap), :(_ + 1) )
```
"""
lambda(f::Expr, e, v = :_) = MacroTools.@match f begin
    function_call_(arguments__) => @chain begin
        e
        lambda
        Expr(:call, function_call, _, arguments..., v)
    end
    f_=> error("`f` must be a call")
end

@nonstandard lambda
export @lambda

"""
    @map(e, v = \_)

A convenience macro for [`lambda`](@ref) where `f` = `map`

# Examples
```julia
_ = [1, 2]
@test map(_ -> vcat(_, 1), _) == @map vcat(_, 1)
```
"""
macro map(e, v = :_)
    esc(lambda(:map, e, v))
end
export @map
