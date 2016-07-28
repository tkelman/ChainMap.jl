# ChainMap.jl

This package attempts to integrate mapping and chaining. The chaining code owes
heavily to one-more-minute/Lazy.jl.

| **Documentation**                                                               | **PackageEvaluator**                                            | **Build Status**                                                                                |
|:-------------------------------------------------------------------------------:|:---------------------------------------------------------------:|:-----------------------------------------------------------------------------------------------:|
| [![][docs-stable-img]][docs-stable-url] [![][docs-latest-img]][docs-latest-url] | [![][pkg-0.4-img]][pkg-0.4-url] [![][pkg-0.5-img]][pkg-0.5-url] | [![][travis-img]][travis-url] [![][appveyor-img]][appveyor-url] [![][codecov-img]][codecov-url] |

## Documentation

- [**STABLE**][docs-stable-url] &mdash; **most recently tagged version of the documentation.**
- [**LATEST**][docs-latest-url] &mdash; *in-development version of the documentation.*

## Chaining

Here is a short example to illustrate the chaining mechanism.

```julia
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

## Argument building

There is another mechanism of argument storage. This is conceptually the
inverse of chaining. Here is an example:

```julia
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
functions included: `@nonstandard`, `@safe`, and `@multiblock`. See docstrings
for more information. Note that these functions were used to generate the
package itself. Standard evaluation versions exist for all exported macros.

## Aliasing

If you want shorter versions of the chaining functions for convenience, run the
`@make_aliases` macro. This will create, for example, the `@c` macro as
identical to `@chain`.

[docs-latest-img]: https://img.shields.io/badge/docs-latest-blue.svg
[docs-latest-url]: https://bramtayl.github.io/ChainMap.jl/latest

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://bramtayl.github.io/ChainMap.jl/stable

[travis-img]: https://travis-ci.org/bramtayl/ChainMap.jl.svg?branch=master
[travis-url]: https://travis-ci.org/bramtayl/ChainMap.jl

[appveyor-img]: https://ci.appveyor.com/api/projects/status/github/bramtayl/ChainMap.jl?svg=true&branch=master
[appveyor-url]: https://ci.appveyor.com/project/bramtayl/chainmap-jl/branch/master

[codecov-img]: https://coveralls.io/repos/bramtayl/ChainMap.jl/badge.svg?branch=master&service=github
[codecov-url]: https://coveralls.io/github/bramtayl/ChainMap.jl?branch=master

[issues-url]: https://github.com/bramtayl/ChainMap.jl/issues

[pkg-0.4-img]: http://pkg.julialang.org/badges/ChainMap_0.4.svg
[pkg-0.4-url]: http://pkg.julialang.org/?pkg=ChainMap
[pkg-0.5-img]: http://pkg.julialang.org/badges/ChainMap_0.5.svg
[pkg-0.5-url]: http://pkg.julialang.org/?pkg=ChainMap
