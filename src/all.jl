export chain_map
"""
    @chain_map(e, associative = \_)

The `@chain_map` macro combines three different macros. [`with`](@ref) annotates
<<<<<<< HEAD
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
=======
each symbol with `associative`. [`chain`](@ref) chains together
expressions wrapped in a `begin` block. [`@broadcast`](@ref) does broadcasting
of woven expressions.
>>>>>>> halp

# Examples
```julia
a = ["one", "two"]
result = @chain begin
    Dict(:b => [1, 2], :c => ["I", "II"])
    @chain_map begin
        :b
        sum
        string
        *(~a, " ", _, " ", ~:c)
    end
end

@test result == ["one 3 I", "two 3 II"]
```
"""
chain_map(e, associative = :_) = @chain begin
    e
    chain
<<<<<<< HEAD
<<<<<<< HEAD
    with(_, v)
    unweave(:(NullableArrays.broadcast(lift = true)), _)
=======
    with(_, associative)
    unweave(:broadcast, _)
>>>>>>> 13bff6a... misc
=======
    with(_, associative)
    unweave(:broadcast, _)
>>>>>>> halp
end

@nonstandard chain_map
export @chain_map
