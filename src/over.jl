export over!, @o, bitnot

"""
    bitnot

Alias for `~` for use within `@o`
"""
bitnot = ~

replace_record!(e, d) = (e, d)
function replace_record!(e::Expr, d)
  if MacroTools.@capture e begin ~(key_) end
    if @c d haskey(key) !
      d[key] =
        MacroTools.isexpr(key, :...) ?
        Expr(:..., gensym() ) : gensym()
    end
    e = d[key]
  else
    e.args = @c e.args MacroTools.rmlines() map(e -> replace_record!(e, d)[1], _)
  end
  (e, d)
end

"""
    over(e)

Standard evalution version of `@o`
"""
function over!(e)
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
  @c e over! esc
end
