export link

"""
<<<<<<< HEAD
<<<<<<< HEAD
    @chain head tail
=======
    @link head tail::Symbol
>>>>>>> 13bff6a... misc
=======
    @link head tail::Symbol
>>>>>>> halp

Calls `head` on `tail`

# Examples
```julia
@test vcat(1) == @link 1 vcat
```
"""
<<<<<<< HEAD
<<<<<<< HEAD
chain(head, tail) = Expr(:call, tail, head)
=======
link(head, tail::Symbol) = Expr(:call, tail, head)
>>>>>>> 13bff6a... misc
=======
link(head, tail::Symbol) = Expr(:call, tail, head)
>>>>>>> halp

"""
    @link head tail::Expr

Reinterprets `\_` in `tail` as `head`.

# Examples
```julia
@test vcat(2, 1) == @link 1 vcat(2, _)
```
"""
link(head, tail::Expr) = Expr(:let, tail, Expr(:(=), :_, head))

<<<<<<< HEAD
<<<<<<< HEAD
chain(head, tail::AnnotatedLine) =
    AnnotatedLine(tail.line, chain(convert(Expr, head), tail.expr) )
=======
link(head, tail::AnnotatedLine) =
    AnnotatedLine(tail.line, link(convert(Expr, head), tail.expression) )
>>>>>>> 13bff6a... misc
=======
link(head, tail::AnnotatedLine) =
    AnnotatedLine(tail.line, link(convert(Expr, head), tail.expression) )
>>>>>>> halp

@nonstandard link
export @link

export chain_line
"""
    @chain_line es...

<<<<<<< HEAD
<<<<<<< HEAD
`reduce` `@chain` over `es`
=======
`reduce` [`link`](@ref) over `es`
>>>>>>> 13bff6a... misc
=======
`reduce` [`link`](@ref) over `es`
>>>>>>> halp

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
<<<<<<< HEAD

<<<<<<< HEAD
Separate single begin blocks out into lines and [`chain`](@ref) them;
return single non-blocks.
=======
Separate `begin` blocks out into lines and [`chain_line`](@ref) them.

`e` must be a `begin` block. Note that dot fusion is broken by this macro.
Instead, use [`unweave`](@ref), [`@map`](@ref), or [`@broadcast`](@ref).
>>>>>>> 13bff6a... misc
=======

Separate `begin` blocks out into lines and [`chain_line`](@ref) them.

`e` must be a `begin` block. Note that dot fusion is broken by this macro.
Instead, use [`unweave`](@ref), [`@map`](@ref), or [`@broadcast`](@ref).
>>>>>>> halp

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
<<<<<<< HEAD
<<<<<<< HEAD
chain(e) =
    if MacroTools.isexpr(e, :block)
        convert(Expr, chain(annotate(e.args)...) )
=======
chain(e::Expr) =
    if e.head == :block
        convert(Expr, foldl(link, annotate(e.args) ) )
>>>>>>> 13bff6a... misc
=======
chain(e::Expr) =
    if e.head == :block
        convert(Expr, foldl(link, annotate(e.args) ) )
>>>>>>> halp
    else
        error("Can only chain begin blocks")
    end

@nonstandard chain
export @chain
