module ChainMap
import MacroTools
export chain, @>, lambda, @f, @fs, chain_map, @.>, chain_map_all, @.>>

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

- If bare `\_` or `\_...` is an argument to `ex`.
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
  esc( chain(exs...) )
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
    :( $ex($x) )
  # substitution only for bare _ and _...
  elseif (:_ in ex.args) |
           (Expr(:..., :_) in ex.args) |
           MacroTools.isexpr(ex,  :->, :block)
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
    lambda(exs..., multi = false)

Standard evaluation version of `@f`. If multi is set to true, stadard evaluation
version of `@fs`
"""
function lambda(exs...; multi = false)

  x = gensym()

  if length(exs) == 1 & MacroTools.isexpr(exs[1], :block)
    # insert x into block then chain
    ex = exs[1]
    x_chain = chain( Expr(ex.head, x, ex.args...) )
  else
    # regular chaining
    x_chain = chain(x, exs...)
  end

  if multi
    Expr( :->, Expr(:..., x), x_chain )
  else
    Expr( :->, x, x_chain )
  end
end

"""
    @f ex...

Will chain together `ex...` expressions using `chain` rules above.
Then, an anonymous function is constructed, with \_ as an input varible.
The input variable may or may not be inserted as the first argument of the first expression.

`@f -(2, \_)` will return `\_ -> -(2, \_)`
`@f +(1)` will return `\_ -> +(\_, 1)`
"""
macro f(exs...)
  esc( lambda(exs...) )
end

"""
    @fs ex...

Same as `@f`, except arguments are passed in as a tuple to the anonymous function.

`@fs +(_...)` will return `function (\_...) +(\_...) end`
"""
macro fs(exs...)
  esc( lambda(exs..., multi = true) )
end

"""
    chain_map(x, exs...; multi = false)

Standard evaluation version of `@>`.
"""
function chain_map(x, exs...; multi = false)
  f = lambda(exs..., multi = multi)

  if multi
    :( broadcast($f, $x...) )
  else
    :( broadcast($f, $x) )
  end

end

"""
    @.> x exs...

will build an anoymous function by chaining together `exs...` using `@f`,
then map that function over `x`.

`@.> [1, 2] +(1)` will return `[1+1, 2+1]`
"""
macro .>(exs...)
  esc(chain_map(exs...) )
end

"""
    @.>> xs exs...

will build an anoymous function by chaining together `exs...` using `@fs`,
then broadcast that function over `xs...`. It is as if zipped tuples are passed
in to the function.

`@.>> ( [1, 2], [3, 4] ) +(_...)` will return `[1+3, 2+4]`
"""
macro .>>(exs...)
  esc( chain_map(exs..., multi = true) )
end

end
