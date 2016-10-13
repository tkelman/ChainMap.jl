export link

"""
    @link head tail

`head[tail]`

# Examples
```julia
v = [1, 2, 3]
@test v[2] == @link v 2

d = Dict( a => 1, b => 2)
@test d[:a] == @link d :a
```
"""
link(head, tail) = Expr(:ref, head, tail)

"""
    @link head tail::Symbol

Calls `head` on `tail`

# Examples
```julia
@test vcat(1) == @link 1 vcat
```
"""
link(head, tail:::Symbol) = Expr(:call, tail, head)

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
    AnnotatedLine(tail.line, link(convert(Expr, head), tail.expr) )

@nonstandard link
export @link

export chain_line
"""
    @chain_line es...

`reduce` `@link` over `es`

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
    @chain e

Separate single begin blocks out into lines and [`chain_line`](@ref) them;
return single non-blocks. Note that dot fusion is broken by
this macro. Instead, use [`unweave`](@ref), [`@map`](@ref), or
[`@broadcast`](@ref).

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
        convert(Expr, foldl(link, annotate(e.args) )
    else
        e
    end

@nonstandard chain
export @chain
