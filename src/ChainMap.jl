module ChainMap
import MacroTools
import Base.==
import Base.run
export chain, @c, lambda, @l, over, @o, bitnot

"""
    bitnot

Alias for `~` for use within `@o`
"""
bitnot = ~

insert(x) = :( $x(_) )
function insert(e::Expr)
  e = e
  site = e.head in [:call, :macrocall] ? 2 : 1
  insert!(e.args, site, :_)
  e
end

incommon(x, y) = length( intersect(x, y) ) > 0

matchexpr(e, heads, args) = false
matchexpr(e::Expr, heads, args) =
  (e.head in heads) | incommon(e.args, args )

maybeinsert(e) =
  matchexpr( e, [:->, :block] ,
                [:_, Expr(:..., :_) ] ) ?
  e : insert(e)

expose(tail, head) = :(let _ = $head; $tail; end)

"""
    chain(x)
    chain(head, tail)
    chain(x, exs...)

Standard evaluation version of `@c`.
"""
chain(single) =
  MacroTools.isexpr(single, :block) ?
  chain(MacroTools.rmlines(single).args...) : single

chain(head, tail) = expose(maybeinsert(tail), head)
chain(head, tails...) = reduce(chain, head, tails)

"""
    @c x

Separate single blocks out into lines and recur, return single non-blocks.

    @c begin
         1
         +(1)
       end

is the same as `@c 1 +(1)`

    @c x ex

`@c` always substitutes `x` into `\_` in `ex`. `@c 1 -(2, \_)` returns `-(2, 1)`

In addition, insertion of `x` to the first argument of `ex` is default.
`@c 1 +(1)` returns `+(1, 1)`

Insertion is overridden in three ways:

- If bare `\_` or `\_...` is an argument to `ex`.
See the first example

- If `ex` is a block.

    @c 1 begin
           b = 2
           -(b, \_)
         end

will translate to

    begin
      b = 2
      -(b, 1)
    end

- If `ex` is a lambda. `@c 1 x -> x + \_` will translate to `x -> x + 1`

    @c x exs...

Reduce `@c` over `(x, exs...)`. `@c 1 -(2) +(3)` is the same as +(-(1, 2), 3)
"""
macro c(exs...)
  esc( chain(exs...) )
end

"""
    lambda(x)

Standard evaluation version of `@l`.
"""
lambda(x) = :(_ -> $x)

"""
    @l x

An anonymous function is constructed, with `_` as an input varible.

`@l -(2, \_)` will return `\_ -> -(2, \_)`
"""
macro l(x)
  esc( lambda(x) )
end

replace_record!(e, d) = (e, d)
function replace_record!(e::Expr, d)
  if MacroTools.@capture e begin ~(key_) end
    if !(haskey(d, key) )
      d[key] =
        MacroTools.isexpr(key, :...) ?
        Expr(:..., gensym() ) : gensym()
    end
    e = d[key]
  else
    e.args = map(e -> replace_record!(e, d)[1], MacroTools.rmlines(e.args) )
  end
  (e, d)
end

"""
    over(e)

Standard evalution version of `@o`
"""
function over(e)
  d = Dict()
  replace_record!(e, d)

  if length(d) == 0
    return e
  end

  dotted = filter((k, v) -> MacroTools.isexpr(k, :...), d)
  undotted = filter((k, v) -> !(MacroTools.isexpr(k, :...)), d)

  if length(dotted) > 1
    error("Cannot map over more than one splatted argument")
  end

  Expr(:call, :broadcast,
       Expr(:->,
            Expr(:tuple,
                 values(undotted)... ,
                 values(dotted)...) ,
            e),
       keys(undotted)... ,
       keys(dotted)... )
end

"""
    @o e

Interprets e as a function to map with, and expressions wrapped with tilda as
objects to broadcast over.

Let `a = [1, 2]`, `b = [3, 4]`, `c = ( [5, 6], [7, 8] )`, `d = 9`

`@o +(~a + ~a + ~b)` = `[1 + 1 + 3, 2 + 2 + 4]`

Objects do not have to be the same size.

`@o +(~a, ~d)` = `[1 + 9, 2 + 9]`

You can also map over splatted arguments.

`@o ~a + ~(c...)` = `( [1 + 5 + 7], [2 + 6 + 8] )`

Make multi-line functions by wrapping in blocks

    @o begin
         e = ~a
         e + 1
       end

yields `[2, 3]`

Tildad expressions do not have to be named.

`@o +( ~[1, 2], ~[3, 4] )` = `[1 + 3, 2 + 4]`

To use `~` as a function, use the alias `bitnot`
"""
macro o(e)
  esc( over(e) )
end

"""
A type that can be used to store arguments. Will store positional and keyword
arguments for later use.
"""
type Arguments
  positional::Tuple
  keyword::Vector{Any}
end

"""
    Arguments(positional...; keyword...)

Construct an Arguments type. Will store positional and keyword arguments for
later use.
"""
function Arguments(positional...; keyword...)
  Arguments(positional, keyword)
end

"""
    push(arguments::Arguments, positional...; keyword...)

Add positional and keyword arguments to an already existing arguments type.
Positional arguments are added at the end.
"""
function push(arguments::Arguments, positional...; keyword...)
  new_positional = (arguments.positional..., positional...)
  new_keyword = vcat(arguments.keyword, keyword)
  Arguments(new_positional, new_keyword)
end

"""
    push(arguments::Arguments, positional...; keyword...)

Add positional and keyword arguments to an already existing arguments type.
Positional arguments are added at the start.
"""
function unshift(arguments::Arguments, positional...; keyword...)
  new_positional = (positional..., arguments.positional...)
  new_keyword = vcat(keyword, arguments.keyword)
  Arguments(new_positional, new_keyword)
end

"""
    ==(a::Arguments, b::Arguments)

Test whether the contents and order of positional arguments is the same, and
that the same keyword arguments are present ignoring order.
"""
==(a::Arguments, b::Arguments) =
  (a.positional == b.positional) &
  (length(symdiff(a.keyword, b.keyword) ) == 0)

"""
     run(a::Arguments, f

Call `f` on the arguments in `a`
"""
run(a::Arguments, f) = f(a.positional...; a.keyword...)

end
