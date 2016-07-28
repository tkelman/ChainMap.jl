@doc """
    @safe(fs...)

Defines a new version of mutate-in-place functions like `push!` that copies the
first positional argument before processing.

The new function will have a name without !, like `push`. Can be used on
multiple functions.

# Examples
```julia
push1!(a) = push!(a, 1)
push2!(a) = push!(a, 2)

@safe push1! push2!
a = [0]
b = [0, 1, 2]
c = @chain a push1 push2
Test.@test a != b == c
```
""" :(@safe)

@doc """
    @chain single

Separate single blocks out into lines and recur, return single non-blocks.

    @chain head tail

`@chain` always substitutes `head` into `\_` in `tail`.

In addition, insertion of `head` to the first argument of `tail` is default. if
tail has no arguments, it will be called on head only. Insertion is overridden
in two ways: if bare `\_` or `\_...` is an argument to `tail`, or if `tail` is a
block.

    @chain head tails...

Reduce `@chain` over `(head, tails...)`.

# Examples
```julia
plus(a, b) = a + b
minus(a, b) = a - b
plusone(a) = a + 1

Test.@test (@chain begin
                     1
                     plus(1)
                   end) ==
           @chain 1 plus(1)

Test.@test (@chain 1 plusone) == plusone(1)

Test.@test (@chain 1 minus(2, _) ) ==
           minus(2, 1)

Test.@test (@chain 1 plus(2) ) ==
           plus(1, 2)

Test.@test (@chain begin
                     1
                     begin
                       b = 2
                       minus(b, _)
                     end
                   end) ==
           begin
             b = 2
             minus(b, 1)
           end

Test.@test (@chain 1 minus(2) plus(3) ) ==
           plus(minus(1, 2), 3)
```
"""  :(@chain)

@doc """
    @lambda(e)

An anonymous function is constructed, with `_` as an input varible.

# Examples
```julia
testlambda = @lambda -(2, _)
Test.@test  testlambda(1) == -(2, 1)
```
"""  :(@lambda)

@doc """
    @over e

Interprets e as a function to broadcast with, and expressions wrapped with
tildas as objects to broadcast over.

You can also map over splatted arguments, but only one. Make multi-line
functions by wrapping in blocks. To use `~` as a function, use the alias
`bitnot`.

# Examples

```julia
Test.@test (@over 1) == 1
Test.@test (@over 1 + 2) == 3

Test.@test (@over +( ~[1, 2], ~[3, 4] ) ) ==
           [1 + 3, 2 + 4]

a = [1, 2]
b = [3, 4]
c = ( [5, 6], [7, 8] )
d = 9

Test.@test (@over ~a + ~a + ~b) ==
           [1 + 1 + 3, 2 + 2 + 4]

Test.@test (@over +(~a, ~d) ) ==
           [1 + 9, 2 + 9]

Test.@test (@over ~a + ~(c...) ) ==
           [ 1 + 5 + 7, 2 + 6 + 8 ]

Test.@test (@over begin
                    e = ~a
                    e + 1
                  end ) ==
            [2, 3]
```
"""  :(@over)

@doc """
    bitnot

Alias for `~` for use within `@over`.

# Examples
```julia
Test.@test bitnot(1) == ~1
```
""" bitnot

@doc """
    Arguments

A type that can be used to store arguments. Will store positional and keyword
arguments for later use.

# Examples
```julia
a = Arguments(1, 2, a = 3, b = 4)
Test.@test a.positional ==
           (1, 2)
Test.@test a.keyword ==
           Dict{Symbol, Any}(:a => 3, :b => 4)
```
""" Arguments

@doc """
    push(arguments::Arguments, positional...; keyword...)

Add positional and keyword arguments to an already existing arguments type.
Positional arguments are added at the end. Note that push can also be used in
any other context that push! is defined; it will copy the first argument before
executing.

# Examples
```julia
Test.@test (@chain Arguments(1, a = 3) push(2, b = 4) ) ==
           Arguments(1, 2, a = 3, b = 4)
```
""" push

@doc """
    unshift(arguments::Arguments, positional...)

Add positional arguments to an already existing arguments type. Arguments are
added at the start. Note that unshift can also be used in any other context that
unshift! is defined; it will copy the first argument before executing.

# Examples
```julia
Test.@test (@chain Arguments(1, a = 3) unshift(2) ) ==
           Arguments(2, 1, a = 3)
```
""" unshift

@doc """
     run(a::Arguments, f)

Call `f` on the arguments in `a`

# Examples
```julia
testfunction(a, b; c = 4) = a - b + c

Test.@test (@chain Arguments(1, 2, c = 3) run(testfunction) ) ==
           testfunction(1, 2, c = 3)
```
""" run

@doc """
    @nonstandard(fs...)

Will create a nonstandard evaluation macro for each of the fs functions. Each
function should be a function that takes and returns expressions. The
nonstandard macro will have the same name but will take in code, not
expressions, and will evaluate the result locally when the macro is called.

#Examples
```julia
plus(a, b) = +(a, b)
minus(a, b) = -(a, b)

binaryfun(a, b, c) = :(\$b(\$a, \$c))
chainback(a, b, c) = :(\$c(\$b, \$a))

@nonstandard binaryfun chainback

Test.@test (@binaryfun 1 plus 2) == 3
Test.@test (@chainback 2 3 minus) == 1
```
""" :(@nonstandard)

@doc """
    @multiblock(fs...)

If `f1` is a function taking one argument ending in "1" which will generate
code, `f` will be defined. In `f`, `f1` will be mapped over all arguments and
the results will be returned in one code block. This will happen for all `f1`
functions in `fs...`.

# Examples
```julia
line_to_block1(f) = f
double_line_to_block1(f) = :(\$f; \$f)

@multiblock line_to_block1 double_line_to_block1
@nonstandard line_to_block double_line_to_block

(@line_to_block a = 2 a - 1) == 1
@double_line_to_block a = a + 1 a = a/2
Test.@test a == 1
```
""" :(@multiblock)
