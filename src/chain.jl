"""
```julia
    @test ChainMap.replace_(1, 3) == 1
```
"""
replace_(e, head) = e

"""
```julia
    @test ChainMap.replace_(:_, 3) == 3
    @test ChainMap.replace_(:a, 3) == :a
```
"""
replace_(e::Symbol, head) =
    if e == :_
        head
    else
        e
    end

"""
```julia
    @test ChainMap.replace_(:(2 + _ + (1 + _)), 3) ==
        :(2 + 3 + (1 + 3))
```
"""
replace_(e::Expr, head) =
    Expr(e.head, map(e -> replace_(e, head), e.args)...)

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

Reinterprets `\_` in `tail` as `head`.

# Examples
```julia
@test vcat(2, 1) == @chain 1 vcat(2, _)
```
"""
chain(head, tail::Expr) = replace_(tail, head)

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
        chain(MacroTools.rmlines(e).args...)
    else
        e
    end

@nonstandard chain
export @chain
