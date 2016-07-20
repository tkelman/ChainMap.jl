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

chain!(single) =
  MacroTools.isexpr(single, :block) ?
  chain!(MacroTools.rmlines(single).args...) : single
chain!(head, tail) = expose(maybeinsert_!(tail), head)
chain!(head, tails...) = reduce(chain!, head, tails)

lambda(x) = :(_ -> $x)
