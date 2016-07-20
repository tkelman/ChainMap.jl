@doc """
    @safe(fs...)

Defines a new version of mutate-in-place functions like `push!` that copies the
first positional argument before processing. The new function will have a name
without !, like `push`. Can be used on multiple functions.
""" :(@safe)

@doc """
    @allsafe(fs...)

The same as `@safe`, except creates copies of all arguments
"""  :(@allsafe)

@doc """
    @chain x

Separate single blocks out into lines and recur, return single non-blocks.

    @chain begin
         1
         plus(1)
       end

is the same as `@chain 1 plus(1)`

    @chain x ex

`@chain` always substitutes `x` into `\_` in `ex`. `@chain 1 minus(2, \_)` returns
`minus(2, 1)`

In addition, insertion of `x` to the first argument of `ex` is default.
`@chain 1 plus(1)` returns `plus(1, 1)`

Insertion is overridden in two ways:

- If bare `\_` or `\_...` is an argument to `ex`.
See the first example

- If `ex` is a block.

    @chain 1 begin
           b = 2
           minus(b, \_)
         end

will translate to

    begin
      b = 2
      minus(b, 1)
    end

    @chain x exs...

Reduce `@chain` over `(x, exs...)`. `@chain 1 minus(2) plus(3)` is the same as
`plus(minus(1, 2), 3)`
"""  :(@chain)

@doc """
    @lambda x

An anonymous function is constructed, with `_` as an input varible.

`@lambda -(2, \_)` will return `\_  -(2, \_)`
"""  :(@lambda)

@doc """
    @over e

Interprets e as a function to map with, and expressions wrapped with tilda as
objects to broadcast over.

Let `a = [1, 2]`, `b = [3, 4]`, `c = ( [5, 6], [7, 8] )`, `d = 9`

`@over +(~a + ~a + ~b)` = `[1 + 1 + 3, 2 + 2 + 4]`

Objects do not have to be the same size.

`@over +(~a, ~d)` = `[1 + 9, 2 + 9]`

You can also map over splatted arguments.

`@over ~a + ~(c...)` = `( [1 + 5 + 7], [2 + 6 + 8] )`

Make multi-line functions by wrapping in blocks

    @over begin
         e = ~a
         e + 1
       end

yields `[2, 3]`

Tildad expressions do not have to be named.

`@over +( ~[1, 2], ~[3, 4] )` = `[1 + 3, 2 + 4]`

To use `~` as a function, use the alias `bitnot`
"""  :(@over)

@doc """
    bitnot

Alias for `~` for use within `@over`
""" bitnot

@doc """
    Arguments

A type that can be used to store arguments. Will store positional and keyword
arguments for later use.
""" Arguments

@doc """
    push(arguments::Arguments, positional...; keyword...)

Add positional and keyword arguments to an already existing arguments type.
Positional arguments are added at the end. Note that push can also be used in any other
context that push! is defined; it will copy the first argument before executing.
""" :(push)

@doc """
    unshift(arguments::Arguments, positional...)

Add positional arguments to an already existing arguments type. Arguments are added at
the start.  Note that unshift can also be used in any other context that unshift! is
defined; it will copy the first argument before executing.
""" unshift

@doc """
     run(a::Arguments, f)

Call `f` on the arguments in `a`
""" run

@doc """
    @nonstandard(fs)

Will create a nonstandard evaluation macro for each of the fs functions. Each function
should be a function that takes and returns expressions. The nonstandard macro will have
the same name but will take in code, not expressions, and will evaluate the result
locally when the macro is called.
""" :(@nonstandard)
