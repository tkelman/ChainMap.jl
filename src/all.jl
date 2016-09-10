export chain_map
"""
    chain_map(e)

A function which combines three macros in `ChainMap`: [`chain`](@ref), `with`,
and [`unweave`](@ref) with `NullableArrays.broadcast(lift = true)`.

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
chain_map(e) = @chain begin
    e
    chain
    with
    unweave(:(NullableArrays.broadcast(lift = true)), _)
end

@nonstandard chain_map
export @chain_map
