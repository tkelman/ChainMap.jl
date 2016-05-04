module ChainMap
import MacroTools
export chain, @>, lambda, @f, chain_map, @.>, map_all

"""
    @> x

Separate single blocks out into lines and recur, return single non-blocks.

    @> begin
             1
             +(1)
           end

is the same as `@> 1 +(1)`

    @> x ex

`@>` always substitutes `x` into `\_` in `ex`. `@> 1 -(2, \_)` returns `-(2, 1)`

In addition, insertion of `x` to the first argument of `ex` is default. `@> 1 +(1)` returns `+(1, 1)`

Insertion is overridden in three ways:

- If bare `\_` is an argument to `ex`.
See the first example

- If `ex` is a block.

    @> 1 begin
               b = 2
               -(b, \_)
             end

will translate to

    begin
      b = 2
      -(b, 1)
    end

- If `ex` is a lambda. `@> 1, x -> x + \_` will translate to `x -> x + 1`

    @> x exs...

Reduce `@>` over `(x, exs...)`. `@> 1 +1 +1` is the same as +(+(1, 1), 1)
"""
macro >(exs...)
  esc(chain(exs...))
end

"""
    chain(x)
    chain(x, ex)
    chain(x, exs...)

Standard evaluation version of `@>`.
"""
function chain(x)
  MacroTools.isexpr(x, :block) ? chain(MacroTools.rmlines(x).args...) : x
end

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

function chain(x, exs...)
  reduce(chain, x, exs)
end

"""
    lambda(ex)
    lambda(exs...)

Standard evaluation version of `@f`.
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
    @f ex...

Will chain together `ex...` expressions using `chain` rules above.
Then, an anonymous function is constructed, with \_ as an input varible.
The input variable may or may not be inserted as the first argument of the first expression.
`@f -(2, \_)` will return `\_ -> -(2, \_)` and
`@f +(1)` will return `\_ -> +(\_, 1)`
"""
macro f(exs...)
  esc(lambda(exs...))
end

"""
    chain_map(x, exs...)

Standard evaluation version of `@.>`.
"""
chain_map = function(x, exs...)
  Expr(:call, :map, ChainMap.lambda(exs...), x)
end

"""
    @.> x exs...

will build an anoymous function by chaining together `exs...` using `@f`,
then map that function over `x`.
"""
macro .>(exs...)
  esc(chain_map(exs...))
end

"""
    map_all(As, f)

A wrapper for `broadcast` that is chain-friendly.
`As` is a tuple of items to be `broadcast` over, and `f` is a function.
"""
function map_all(As, f)
  broadcast(f, As...)
end

end
