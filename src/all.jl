export chain_map
"""
    @chain_map(e, associative = \_)

The `@chain_map` macro combines three different macros. [`with`](@ref) annotates
<<<<<<< HEAD
each symbol with the associative: `v`. [`chain`](@ref) chains together
expressions wrapped in a `begin` block. [`unweave`](@ref), together with
`NullableArrays.broadcast(lift = true)`, does broadcasting and automatic
lifting of woven expressions.
=======
each symbol with `associative`. [`chain`](@ref) chains together
expressions wrapped in a `begin` block. [`@broadcast`](@ref) does broadcasting
of woven expressions.
>>>>>>> 13bff6a... misc

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
chain_map(e, associative = :_) = @chain begin
    e
    chain
<<<<<<< HEAD
    with(_, v)
    unweave(:(NullableArrays.broadcast(lift = true)), _)
=======
    with(_, associative)
    unweave(:broadcast, _)
>>>>>>> 13bff6a... misc
end

@nonstandard chain_map
export @chain_map
