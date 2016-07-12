module ChainMap
import MacroTools
import Base.==
import Base.run
import Base.copy
import Base.push!
import Base.unshift!
export chain, @c, lambda, @l, over, @o, bitnot

"""
    bitnot

Alias for `~` for use within `@o`
"""
bitnot = ~

insert_!(x) = :( $x(_) )
function insert_!(e::Expr)
  site = e.head in [:call, :macrocall] ? 2 : 1
  placeholder = getplaceholder(forward)
  insert!(e.args, site, placeholder)
  e
end

incommon(x, y) = length( intersect(x, y) ) > 0

matchexpr(e, heads, args) = false
matchexpr(e::Expr, heads, args) =
  (e.head in heads) | incommon(e.args, args )

unblock(e) = e
function unblock(e::Expr)
  e = MacroTools.rmlines(e)
  e.head == :block && length(e.args) == 1 ?
    e.args[1] :
    e
end

test = :(if a == 1; 2; else; 3; end)
test.head

function maybeinsert_!(e, forward = true)
  placeholder = getplaceholder(forward)
  matchexpr( e, [:->, :block, :(=)] ,
                [placeholder, Expr(:..., placeholder) ] ) ?
  e : insert_!(e, forward)
end

function expose(tail, head, forward = true)
  placeholder = getplaceholder(forward)
  Expr(:let,
       tail,
       Expr(:(=), placeholder, head) )
end

link!(head, tail, forward = true) =
  forward ?
    expose(maybeinsert_!(tail), head, forward) :
    expose(maybeinsert_!(head, forward), tail, forward)

pipe!(x) = x
function pipe!(e::Expr)
  pipe!(e.head)
  map!(pipe!, e.args)

  e =
    (e.head == :call) && (e.args[1] in [:<|, :|>] ) ?
      length(e.args) != 3 ?
        error("<| and |> must take exactly arguments") :
        link!(e.args[2], e.args[3], e.args[1] == :|>) :
      e
end

test = :( %(1 + 2) )


macro p(e)
  esc(pipe!(e))
end

@p 1 |> +(2) |> +(3) <| 2 <| 4

pipe!(:( 1 |> +(2) |> +(3) <| 2 <| 4 ))
test =
quote
  let a = 1
    2
  end
end
test.args[2].head

e = :(+(2) <| 1 <| 1)
pipe!(e)
e.args
pipe!(e.args[2])

@p +(2) <| 1 <| 1

test = :(hello(1; a = 2, b = 3))

hello(a, b = 3)

pipe!(:(1 |> +(2) ) )
pipe!(:(hello(2) <| (:hi, 2)) )




"""
    chain(single)
    chain(head, tail)
    chain(head, tails...)

Standard evaluation version of `@c`.
"""
chain(single) =
  MacroTools.isexpr(single, :block) ?
  chain(MacroTools.rmlines(single).args...) : single

chain(head, tail) = expose(maybeinsert_!(tail), head)
chain(head, tails...) = reduce(chain, head, tails)

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

Insertion is overridden in three ways:

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

- If `ex` is a lambda. `@c 1 x -> x + \_` will translate to `x -> x + 1`

    @c x exs...

Reduce `@c` over `(x, exs...)`. `@c 1 minus(2) plus(3)` is the same as
`plus(minus(1, 2), 3)`
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
  @c x lambda esc
end

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
  Arguments(positional, keyword )
end

copy(a::Arguments) = Arguments(a.positional...; a.keyword...)

"""
    push!(arguments::Arguments, positional...; keyword...)

Add positional and keyword arguments to an already existing arguments type.
Positional arguments are added at the end.
"""
function push!(a::Arguments, positional...; keyword...)
  a.positional = (a.positional..., positional...)
  @c a.keyword append!(keyword)
  a
end

function unshift!(a::Arguments, positional...; keyword...)
  a.positional = (positional..., a.positional...)
  @c a.keyword append!(keyword)
  a
end

"""
    @safe(fs...)

Defines a new version of mutate-in-place functions like `push!` that copy the first
argument before processing. The new function will have a name without !, like `push`.
Can take multiple functions.
"""
macro safe(fs...)
  @c fs safe(_...) esc
end

function safe_single(f::Symbol)
  f_string = string(f)
  if @c f_string endswith("!") !
    error("Function must end in !")
  end
  f_chop = @c f_string chop symbol

  :( $f_chop(x, args...; kwargs...) = $f(copy(x), args...; kwargs...) )
end

"""
    safe(fs...)

Standard evaluation version of @safe.
"""
safe(fs...) = @c fs map(safe_single, _) Expr(:block, _...)

"""
    ==(a::Arguments, b::Arguments)

Test whether the contents and order of positional arguments is the same, and
that the same keyword arguments are present ignoring order.
"""
==(a::Arguments, b::Arguments) =
  (a.positional == b.positional) &
  @c a.keyword symdiff(b.keyword) length (_ == 0)

"""
     run(a::Arguments, f)

Call `f` on the arguments in `a`
"""
run(a::Arguments, f) = f(a.positional...; a.keyword...)

end
