[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://bramtayl.github.io/ChainMap.jl/stable)
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://bramtayl.github.io/ChainMap.jl/latest)
#ChainMap

[![ChainMap](http://pkg.julialang.org/badges/ChainMap_0.4.svg)](http://pkg.julialang.org/?pkg=ChainMap)
[![ChainMap](http://pkg.julialang.org/badges/ChainMap_0.5.svg)](http://pkg.julialang.org/?pkg=ChainMap)
[![Build Status](https://travis-ci.org/bramtayl/ChainMap.jl.svg?branch=master)](https://travis-ci.org/bramtayl/ChainMap.jl)
[![Coverage Status](https://coveralls.io/repos/bramtayl/ChainMap.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/bramtayl/ChainMap.jl?branch=master)
[![Build status](https://ci.appveyor.com/api/projects/status/github/bramtayl/ChainMap.jl?svg=true&branch=master)](https://ci.appveyor.com/project/bramtayl/chainmap-jl/branch/master)

This package attempts to integrate mapping and chaining. The chaining code owes
heavily to one-more-minute/Lazy.jl.

## Chaining

Here is a short example to illustrate the chaining mechanism.

```{julia}
readme = @lambda @over @chain begin
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

Three macros, `@chain`, `@lambda`, and `@over`, are included in this mechanism.
See docstrings for more information.

## Argument Building

There is another mechanism of argument storage. This is conceptually the
inverse of chaining. Here is an example:

```{julia}
function test_function(a, b, c; d = 4)
  a - b + c - d
end

test_arguments = @chain begin
  1
  Arguments
  push(2, d = 2)
  unshift(3)
  run(test_function)
end

Test.@test test_arguments == test_function(3, 1, 2; d = 2)
```
There are four functions in this mechanism: `Arguments`, `push`, `unshift`,
and `run`. See docstrings for more information.

## Macro generation

There are several macros that create new functions/macros based on existing
functions included: `@nonstandard`, `@safe`, `@allsafe`, and
`@multiblock`. See docstrings for more information. Note that these functions
were used to generate the package itself. Standard evaluation versions exist for
all exported macros.

## Aliasing

If you want shorter versions of the chaining functions for convenience, run the
code below.

```{julia}
c = ChainMap.chain
o = ChainMap.over
l = ChainMap.lambda
@nonstandard c o l
```

This will create, for example, the `@c` macro as identical to `@chain`.
