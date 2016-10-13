export link

"""
    @link head tail::Symbol

Calls `head` on `tail`

# Examples
```julia
@test vcat(1) == @link 1 vcat
```
"""
link(head, tail::Symbol) = Expr(:call, tail, head)

"""
    @link head tail::Expr

Reinterprets `\_` in `tail` as `head`.

# Examples
```julia
@test vcat(2, 1) == @link 1 vcat(2, _)
```
"""
link(head, tail::Expr) = Expr(:let, tail, Expr(:(=), :_, head))

link(head, tail::AnnotatedLine) =
    AnnotatedLine(tail.line, link(convert(Expr, head), tail.expression) )

@nonstandard link
export @link

export chain_line
"""
    @chain_line es...

`reduce` [`link`](@ref) over `es`

# Examples
```julia
@test ( @chain_line 1 vcat(_, 2) vcat(_, 3) ) ==
    @link ( @link 1 vcat(_, 2) ) vcat(_, 3)
```
"""
chain_line(es...) = foldl(link, es)

@nonstandard chain_line
export @chain_line

"""
    @chain e::Expr

Separate `begin` blocks out into lines and [`chain_line`](@ref) them.

`e` must be a `begin` block. Note that dot fusion is broken by this macro.
Instead, use [`unweave`](@ref), [`@map`](@ref), or [`@broadcast`](@ref).

# Examples
```julia
chain_block = @chain begin
    1
    vcat(_, 2)
end

@test chain_block == @chain_line 1 vcat(_, 2)

@test_throws ErrorException ChainMap.chain(:(a + b))
```
"""
chain(e::Expr) =
    if e.head == :block
        convert(Expr, foldl(link, annotate(e.args) ) )
    else
        error("Can only chain begin blocks")
    end

@nonstandard chain
export @chain
