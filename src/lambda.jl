export lambda

"""
    @lambda anonymous_function::Expr

Convert `anonymous_function` to an anonymous function with `_` as the input
variable.

# Examples
```julia
lambda_function = @lambda vcat(_, 2)
@test lambda_function(1) == vcat(1, 2)
```
"""
lambda(anonymous_function::Expr) = Expr(:->, :_, anonymous_function)

"""
    @lambda(outer_function::Symbol, anonymous_function::Expr, input = :\_)

[`lambda`](@ref) `anonymous_function` then call `outer_function` on
`anonymous_function` and `input`.

# Examples
```julia
outer_function = :map
anonymous_function = :(vcat(_, 1))
lambda(outer_function, anonymous_function)

_ = [1, 2]
@test map(_ -> vcat(_, 1), _) == @lambda map vcat(_, 1)
```
"""
lambda(outer_function::Symbol, anonymous_function::Expr, input = :_) =
    @chain begin
        anonymous_function
        lambda
        Expr(:call, outer_function, _, input)
    end

"""
    @lambda(outer_function::Expr, anonymous_function::Expr, input = \_)

[`lambda`](@ref) `anonymous_function` then insert `anonymous_function` as as the
first and `input` as the last argument to `outer_function`.

`outer_function` must be a call.

# Examples
```julia
<<<<<<< HEAD
e = :(_ + 1)
f = :(NullableArrays.map(lift = true))
=======
anonymous_function = :(_ + 1)
outer_function = :( mapreduce(*) )
>>>>>>> 13bff6a... misc

lambda(outer_function, anonymous_function)

_ = NullableArrays.NullableArray([1, 2], [false, true])

result = @lambda NullableArrays.broadcast(lift = true) _ + 1

@test result.values[1] == 2
@test result.isnull == [false, true]

# `f` must be a call
@test_throws ErrorException lambda(:(import ChainMap), :(_ + 1) )
```
"""
lambda(outer_function::Expr, anonymous_function::Expr, input = :_) =
    MacroTools.@match outer_function begin
        function_call_(arguments__) => @chain begin
            anonymous_function
            lambda
            Expr(:call, function_call, _, arguments..., input)
        end
        outer_function_=> error("`outer_function` must be a call")
    end

@nonstandard lambda
export @lambda

"""
    @map(anonymous_function::Expr, input = \_)

A convenience macro for [`lambda`](@ref) where `outer_function` = `map`

# Examples
```julia
_ = [1, 2]
@test map(_ -> vcat(_, 1), _) == @map vcat(_, 1)
```
"""
macro map(anonymous_function, input = :_)
    esc(lambda(:map, anonymous_function, input))
end
export @map
