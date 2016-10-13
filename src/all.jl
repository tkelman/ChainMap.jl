export chain_map
"""
    @chain_map(e, v = \_)

The `@chain_map` macro combines three different macros. [`with`](@ref) annotates
each symbol with the associative: `v`. [`chain`](@ref) chains together
expressions wrapped in a `begin` block. [`@broadcast`](@ref) does broadcasting
of woven expressions.

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
chain_map(e, v = :_) = @chain begin
    e
    chain
    with(_, v)
    unweave(:broadcast, _)
end

@nonstandard chain_map
export @chain_map
