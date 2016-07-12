# ChainMap

[![ChainMap](http://pkg.julialang.org/badges/ChainMap_0.4.svg)](http://pkg.julialang.org/?pkg=ChainMap)
[![ChainMap](http://pkg.julialang.org/badges/ChainMap_0.5.svg)](http://pkg.julialang.org/?pkg=ChainMap)
[![Build Status](https://travis-ci.org/bramtayl/ChainMap.jl.svg?branch=master)](https://travis-ci.org/bramtayl/ChainMap.jl)
[![Coverage Status](https://coveralls.io/repos/bramtayl/ChainMap.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/bramtayl/ChainMap.jl?branch=master)
[![Build status](https://ci.appveyor.com/api/projects/status/github/bramtayl/ChainMap.jl?svg=true&branch=master)](https://ci.appveyor.com/project/bramtayl/chainmap-jl/branch/master)

This package attempts to integrate mapping and chaining. The chaining code owes
heavily to one-more-minute/Lazy.jl. Here is a short example to illustrate the
different kind of things you can do with this package.

```{julia}
readme = @l @o @c begin
  ~_
  -(1)
  ^(2, _)
  begin
    a = _ - 1
    b = _ + 1
    (a, b)
  end
  sum
end

Test.@test readme([1, 2]) == [2, 4]
```

There is an additional macro that makes copy versions of mutate in place
functions

```{julia}
@safe push! unshift!

a = [1, 2]
b = @c a push(1) unshift(2)
Test.@test a != b
```

Here is a short list of exported macros and what they do. See
docstrings for more information about each function.

    Macro   Standard evaluation   Description
    ----------------------------------------------------------------------------
    @c      chain!                Chain functions
    @l      lambda                Turn into a lambda with _ as the input variable
    @o      over!                 Broadcast expression over tildad objects
    @safe   safe                  Create safe versions of mutate-in-place functions

There is another mechanism of argument storage. This is conceptually the
inverse of chaining. Here is an example:

```{julia}
function test_function(a, b, c; d = 4)
  a - b + c - d
end

test_arguments = @c begin
  1
  Arguments
  push!(2, d = 2)
  unshift!(3)
  run(test_function)
end

Test.@test test_arguments == test_function(3, 1, 2; d = 2)
```
There are four functions in this mechanism: `Arguments`, `push!`, `unshift!`,
and `run`. I recommending using the `@safe` macro to add push and unshift.
