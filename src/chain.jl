export chain

"""
    @chain head tail

Calls `head` on `tail`

# Examples
```julia
@test vcat(1) == @chain 1 vcat
```
"""
chain(head, tail) = Expr(:call, tail, head)

"""
    @chain head tail::Expr

Reinterprets `\_` in `tail` as `head`. Note that dot vectorization is broken by
this macro. Instead, use [`unweave`](@ref), [`@map`](@ref), or [`@broadcast`](@ref)

# Examples
```julia
@test vcat(2, 1) == @chain 1 vcat(2, _)
```
"""
chain(head, tail::Expr) = Expr(:let, tail, Expr(:(=), :_, head))

chain(head, tail::AnnotatedLine) =
    AnnotatedLine(tail.line, chain(convert(Expr, head), tail.expr) )

"""
    @chain es...

`reduce` `@chain` over `es`

# Examples
```julia
@test ( @chain 1 vcat(_, 2) vcat(_, 3) ) ==
    @chain ( @chain 1 vcat(_, 2) ) vcat(_, 3)
```
"""
chain(es...) = foldl(chain, es)

"""
    @chain e

Separate single begin blocks out into lines and [`chain`](@ref) them;
return single non-blocks.

# Examples
```julia
@test 1 == @chain 1

chain_block = @chain begin
    1
    vcat(_, 2)
end

@test chain_block == @chain 1 vcat(_, 2)
```
"""
chain(e) =
    if MacroTools.isexpr(e, :block)
        convert(Expr, chain(annotate(e.args)...) )
    else
        e
    end

@nonstandard chain
export @chain
