export lambda
"""
    @lambda e

Convert to an anonymous function with `_` as the input variable.

# Examples
```julia
lambda_function = @lambda vcat(_, 2)
@test lambda_function(1) == vcat(1, 2)
```
"""
lambda(e) = Expr(:->, :_, e)

"""
    @lambda(f, e, v = :\_)

`lambda` `e` then call `f` on `e` and `v`.

# Examples
```julia
f = :map
e = :(vcat(_, 1))
lambda(f, e)

_ = [1, 2]
@test [[1, 1], [2, 1]] == @lambda map vcat(_, 1)
```
"""
lambda(f, e, v = :_) = @chain begin
    e
    lambda(_)
    Expr(:call, f, _, v)
end

"""
    @unweave(f::Expr, e, v = :\_)

`lambda` `e` then insert `e` and `v` as the first two arguments to `f`.

# Examples
```julia
e = :(_ + 1)
f = :(NullableArrays.map(lift = true))

lambda(f, e)

_ = NullableArrays.NullableArray([1, 2], [false, true])

result = @lambda NullableArrays.broadcast(lift = true) _ + 1

@test result.values[1] == 2
@test result.isnull == [false, true]

# `f` must be in the form `function_call_(arguments__)`
@test_throws ErrorException lambda(:(import ChainMap), :(_ + 1) )
```
"""
function lambda(f::Expr, e, v = :_)

    function_test = MacroTools.@capture f function_call_(arguments__)

    if !(function_test)
        error("`f` must be in the form `function_call_(arguments__)`")
    end

    @chain begin
        e
        lambda(_)
        Expr(:call, function_call, _, v, arguments...)
    end
end


@nonstandard lambda
export @lambda
