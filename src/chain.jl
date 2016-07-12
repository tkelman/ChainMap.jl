export chain!, @c

insert_!(x) = :( $x(_) )
function insert_!(e::Expr)
  site = e.head in [:call, :macrocall] ? 2 : 1
  insert!(e.args, site, :_)
  e
end

incommon(x, y) = length( intersect(x, y) ) > 0

matchexpr(e, heads, args) = false
matchexpr(e::Expr, heads, args) =
  (e.head in heads) | incommon(e.args, args )

maybeinsert_!(e) =
  matchexpr( e, [:block] ,
                [:_, Expr(:..., :_) ] ) ?
  e : insert_!(e)

expose(tail, head) = :(let _ = $head; $tail; end)

"""
    chain!(single)
    chain!(head, tail)
    chain!(head, tails...)

Standard evaluation version of `@c`.
"""
chain!(single) =
  MacroTools.isexpr(single, :block) ?
  chain!(MacroTools.rmlines(single).args...) : single

chain!(head, tail) = expose(maybeinsert_!(tail), head)
chain!(head, tails...) = reduce(chain!, head, tails)

"""
    @c x

Separate single blocks out into lines and recur, return single non-blocks.

    @c begin
         1
         plus(1)
       end

is the same as `@c 1 plus(1)`

    @c x ex

`@c` always substitutes `x` into `\_` in `ex`. `@c 1 minus(2, \_)` returns
`minus(2, 1)`

In addition, insertion of `x` to the first argument of `ex` is default.
`@c 1 plus(1)` returns `plus(1, 1)`

Insertion is overridden in two ways:

- If bare `\_` or `\_...` is an argument to `ex`.
See the first example

- If `ex` is a block.

    @c 1 begin
           b = 2
           minus(b, \_)
         end

will translate to

    begin
      b = 2
      minus(b, 1)
    end

    @c x exs...

Reduce `@c` over `(x, exs...)`. `@c 1 minus(2) plus(3)` is the same as
`plus(minus(1, 2), 3)`
"""
macro c(exs...)
  esc( chain!(exs...) )
end
