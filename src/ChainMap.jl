module ChainMap
import MacroTools
export chain, @c, lambda, @l, over, @o

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

Reduce `@c` over `(x, exs...)`. `@c 1 +1 +1` is the same as +(+(1, 1), 1)
"""
macro c(exs...)
  esc( chain(exs...) )
end

"""
    chain(x)
    chain(x, ex)
    chain(x, exs...)

Standard evaluation version of `@c`.
"""
function chain(x)
  MacroTools.isexpr(x, :block) ? chain(MacroTools.rmlines(x).args...) : x
end

function chain(x, ex)
  # bare function calls
  if MacroTools.isexpr(ex, Symbol)
    :( $ex($x) )
  # substitution only for bare _ and _..., blocks, and lambdas
  elseif (:_ in ex.args) |
           (Expr(:..., :_) in ex.args) |
           MacroTools.isexpr(ex,  :->, :block)
    :(let _ = $x; $ex; end)
  # insertion and substitution for non-functions
  elseif MacroTools.isexpr(ex, :vect, :tuple)
    ex_insert = Expr(ex.head, x, ex.args...)
    :(let _ = $x; $ex_insert; end)
  # insertion and substitution for function calls
  elseif MacroTools.isexpr(ex, :call, :macrocall)
    ex_insert = Expr(ex.head, ex.args[1],
                     x, ex.args[2:end]...)
    :(let _ = $x; $ex_insert; end)
  else
    error("Unsupported expression $ex")
  end
end

function chain(x, exs...)
  reduce(chain, x, exs)
end

"""
    lambda(exs...)

Standard evaluation version of `@l`.
"""
function lambda(exs...)
  x = gensym()

  if length(exs) == 1 & MacroTools.isexpr(exs[1], :block)
    # insert x into block then chain
    ex = exs[1]
    x_chain = chain( Expr(ex.head, x, ex.args...) )
  else
    # regular chaining
    x_chain = chain(x, exs...)
  end

  Expr( :->, x, x_chain )
end

"""
    @l ex...

Will chain together `ex...` expressions using `chain` rules above.
Then, an anonymous function is constructed, with \_ as an input varible.
The input variable may or may not be inserted as the first argument of the first
expression.

`@l -(2, \_)` will return `\_ -> -(2, \_)`
`@l +(1)` will return `\_ -> +(\_, 1)`
"""
macro l(exs...)
  esc( lambda(exs...) )
end

replace_record!(e, d) = (e, d)
function replace_record!(e::Expr, d)
  if ( e.head == :call ) & ( length(e.args) == 2 ) & ( e.args[1] == :~ )
    key = e.args[2]
    if !(haskey(d, key) )
      if MacroTools.isexpr(key, :...)
        d[key] = Expr(:..., gensym() )
      else
        d[key] = gensym()
      end
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

`@o +(~a + ~(c...) )` = `( [1 + 5 + 7], [2, + 6 + 8] )`

Make multi-line functions by wrapping in blocks

    @o begin
         e = ~a
         e + 1
       end

yields `[2, 3]`

Tildad expressions do not have to be named.

`@o +( ~[1, 2], ~[3, 4] )` = `[1 + 3, 2 + 4]`
"""
macro o(e)
  esc( over(e) )
end

end
