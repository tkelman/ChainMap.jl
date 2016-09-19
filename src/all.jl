export chain_map
"""
    @chain_map(e, v = \_)

The `@chain_map` macro combines three different macros. [`with`](@ref) annotates
each symbol with the associative: `v`. [`chain`](@ref) chains together
expressions wrapped in a `begin` block. [`unweave`](@ref), together with
`NullableArrays.broadcast(lift = true)`, does broadcasting and automatic
lifting of woven expressions.

# Examples
```julia
na =  NullableArrays.NullableArray
a = na(["one", "two"], [false, true])
result = @chain begin
    Dict(:b => na([1, 2]), :c => na(["I", "II"]))
    @chain_map begin
        :b
        sum
        get
        string
        *(~a, " ", _, " ", ~:c)
    end
end

@test get(result[1]) == "one 3 I"
@test result.isnull == [false, true]
```
"""
chain_map(e, v = :_) = @chain begin
    e
    chain
    with(_, v)
    unweave(:(NullableArrays.broadcast(lift = true)), _)
end

@nonstandard chain_map
export @chain_map
