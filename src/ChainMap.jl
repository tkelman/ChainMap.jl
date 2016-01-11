module ChainMap
import MacroTools
export chain, @chain, lambda, @lambda, chain_map, @chain_map, map_all

"""
Non-standard evaluation version of chain.
"""
macro chain(exs...)
  esc(chain(exs...))
end

"""
    chain(x)

Separate single blocks out into lines and recur, return single non-block expressions.
"""
function chain(x)
  MacroTools.isexpr(x, :block) ? chain(MacroTools.rmlines(x).args...) : x
end

"""
    chain(x, ex)

chain always substitutes the first argument into _ in the second. `chain(:a, :( -(b, _) )` returns `:( -(b, a) )`

In addition, insertion of x to the first argument of ex is default. `chain(:a, :( +(b) )` returns `:( +(a, b) )`

Insertion is overwriden in three ways:

1) If bare `_` is an argument to ex.
See the first example

2) If ex is a block.
     chain :a quote
                b = 1
                -(b, _)
              end
will translate to `:(-(b, a))`

3) If ex is a lambda.
    chain(:a, :(x -> x + _) )
will translate to `:(x -> x + a)`
"""
function chain(x, ex)
  # bare function calls
  if MacroTools.isexpr(ex, Symbol)
    Expr(:call, ex, x)
  # substitution only
  elseif (:_ in ex.args) | MacroTools.isexpr(ex,  :->, :block)
    :(let _ = $x
        $ex
      end)
  # insertion and substitution for non-functions
  elseif MacroTools.isexpr(ex, :vect, :tuple)
    ex_insert = Expr(ex.head, x, ex.args...)
    :(let _ = $x
        $ex_insert
      end)
  # insertion and substitution for function calls
  elseif MacroTools.isexpr(ex, :call, :macrocall)
    ex_insert = Expr(ex.head, ex.args[1],
                     x, ex.args[2:end]...)
    :(let _ = $x
        $ex_insert
      end)
  else
    error("Unsupported expression $ex")
  end
end

"""
    chain(x, exs...)

Reduce chain over `(x, exs...)`
"""
function chain(x, exs...)
  reduce(chain, x, exs)
end

"""
    lambda(ex...)

Will chain together ex... expressions using chain rules above.
Then, an anonymous function is constructed, with _ being the input varible.
The input variable may or may not be inserted as the first argument of the first expression.
`lambda(:(+(1)), :(+(2)))` will return `:(_ -> +(+(_, 1), 2))` and
`lambda(:(+(1)), :(+(2)))` will return `:(_ -> +(+(1, _), 2))`
"""
function lambda(ex)
  x = gensym()

  ex_chain = MacroTools.isexpr(ex, :block) ?
    ChainMap.chain( Expr(ex.head, x, ex.args...) ) :
    ChainMap.chain( x, ex)

  Expr(:->, x, ex_chain)
end

function lambda(exs...)
  x = gensym()
  Expr(:->, x, ChainMap.chain(x, exs...))
end

"""
Non-standard evaluation version of lambda
"""
macro lambda(exs...)
  esc(lambda(exs...))
end

"""
    chain_map(x, exs...)

will build the code for an anoymous function by chaining together exs using lambda,
then build a map expression for mapping that function over x.
"""
chain_map = function(x, exs...)
  Expr(:call, :map, ChainMap.lambda(exs...), x)
end

"""
Non-standard evaluation version of chain_map.
"""
macro chain_map(exs...)
  esc(chain_map(exs...))
end

"""
    map_all(As, f)

A wrapper for broadcast that is chain-friendly.
As is a tuple of items to be broadcast over, and f is a function.
"""
function map_all(As, f)
  broadcast(f, As...)
end

end
