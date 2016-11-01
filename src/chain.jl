export @chain

immutable AnnotatedLine
    line::Expr
    expression
end

annotate(arguments) = begin
    odd_indices = 1:2:length(arguments)
    map(index -> AnnotatedLine(arguments[index], arguments[index + 1] ),
        odd_indices)
end

Base.convert(::Type{Expr}, a::AnnotatedLine) =
    Expr(:block, a.line, a.expression)

"""
    @link head tail::Symbol

Calls `head` on `tail`

# Examples
```julia
head = 1
tail = :vcat
```
"""
link(head, tail::Symbol) = Expr(:call, tail, head)

"""
    @link head tail::Expr

Reinterprets `\_` in `tail` as `head`.

# Examples
```julia
head = 1
tail = :( vcat(2, _) )
```
"""
link(head, tail::Expr) = Expr(:let, tail, Expr(:(=), :_, head ) )

link(head, tail::AnnotatedLine) =
    AnnotatedLine(
        tail.line,
        link(convert(Expr, head), tail.expression) )

"""
    constant dead_ends

A vector of expression types with no return.
"""
const dead_ends = [:function, :(=>), :(=), :export, :import, :type]

is_dead_end(e) = false
is_dead_end(e::Expr) = e.head in dead_ends

"""
    @chain_block e::Expr

Separate `begin` blocks out into lines and reduce [`link`](@ref) over them.

# Examples
```julia
e = quote
    1
    vcat(_, 2)
end
```
"""
chain_block(e::Expr) = convert(Expr, foldl(link, annotate(e.args) ) )

"""
```julia
e = quote
    begin
        1
        vcat(2, _)
    end
    vcat(_, begin
        2
        vcat(3, _)
    end)
    vcat(3, _)
end
```
"""
chain(e) = e
chain(e::Expr) =
    if e.head == :type
        e
    else
        e_chained_arguments = map_expression(e, chain)

        if e.head == :block && !any( is_dead_end.(e.args) )
            chain_block(e_chained_arguments)
        else
            e_chained_arguments
        end
    end

"""
    @chain(e)

Will `chain` all eligible block in your code, recursively.

Within each block, lines are reduced with `link`. `link` has two behaviors.
It will call bare functions on the result of the previous line. It will
reinterpret `_` within expressions as the result of the previous line.

Cannot chain blocks with expressions that return no output
`[function, =, export, import, =>]`. They will be skipped; however, blocks
inside these blocks will still be `chain`ed. Type definitions will not be
chained nor recurred into.

Like all macros, difficulty might result if you define a macro inside `@chain`.
You can not export from within blocks. Docstrings will not be registered within
blocks.

```julia
@chain begin
    test = begin
        begin
            1
            vcat(2, _)
        end
        vcat(_, begin
            2
            vcat(3, _)
        end)
        vcat(3, _)
    end

    @test test == vcat(3, vcat(vcat(2, 1), vcat(3, 2) ) )
end
```
"""
macro chain(e...)
    esc( chain(e...) )
end
