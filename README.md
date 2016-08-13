# ChainMap.jl

This package attempts to integrate mapping and chaining. The chaining code owes
heavily to one-more-minute/Lazy.jl.

| **Documentation**                                                               | **PackageEvaluator**                                            | **Build Status**                                                                                |
|:-------------------------------------------------------------------------------:|:---------------------------------------------------------------:|:-----------------------------------------------------------------------------------------------:|
| [![][docs-stable_image]][docs-stable_url] [![][docs-latest_image]][docs-latest_url] | [![][pkg-0.4_image]][pkg-0.4_url] [![][pkg-0.5_image]][pkg-0.5_url] | [![][travis_image]][travis_url] [![][appveyor_image]][appveyor_url] [![][codecov_image]][codecov_url] |

## Documentation

- [**STABLE**][docs-stable_url] &mdash; **most recently tagged version of the documentation.**
- [**LATEST**][docs-latest_url] &mdash; *in-development version of the documentation.*

## Fun example

Here is a fun example which includes some of the main feature of this package.
First, design a custom method of combining function calls into a new function
call.

```julia
ChainMap.run(l::LazyCall,
             map_call::typeof(map),
             slice_call::LazyCall{typeof(slice)}) =
    mapslices(l.function_call, l.arguments.positional[1],
              slice_call.arguments.positional[1] )

Base.run(l::LazyCall,
         map_call::typeof(map),
         slice_call::LazyCall{typeof(slice)},
         reduce_call::LazyCall{typeof(reduce)}) =
    mapreducedim(l.function_call, reduce_call.arguments.positional[1],
                 l.arguments.positional[1], slice_call.arguments.positional[1] )
```

Now put it into action!

```julia
fancy = @chain begin
    [1, 2, 3, 4]
    reshape(2, 2)
    begin @unweave (~_ + 1)/~_ end
    @arguments_block begin
        map
        @lazy_call slice(1)
        @lazy_call reduce(+)
    end
    run
end

boring = mapreducedim(x -> (x + 1)/x, +, reshape([1, 2, 3, 4], 2, 2), 1)

@test fancy == boring
```

[docs-latest_image]: https://img.shields.io/badge/docs-latest-blue.svg
[docs-latest_url]: https://bramtayl.github.io/ChainMap.jl/latest

[docs-stable_image]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable_url]: https://bramtayl.github.io/ChainMap.jl/stable

[travis_image]: https://travis-ci.org/bramtayl/ChainMap.jl.svg?branch=master
[travis_url]: https://travis-ci.org/bramtayl/ChainMap.jl

[appveyor_image]: https://ci.appveyor.com/api/projects/status/github/bramtayl/ChainMap.jl?svg=true&branch=master
[appveyor_url]: https://ci.appveyor.com/project/bramtayl/chainmap-jl/branch/master

[codecov_image]: https://coveralls.io/repos/bramtayl/ChainMap.jl/badge.svg?branch=master&service=github
[codecov_url]: https://coveralls.io/github/bramtayl/ChainMap.jl?branch=master

[issues_url]: https://github.com/bramtayl/ChainMap.jl/issues

[pkg-0.4_image]: http://pkg.julialang.org/badges/ChainMap_0.4.svg
[pkg-0.4_url]: http://pkg.julialang.org/?pkg=ChainMap
[pkg-0.5_image]: http://pkg.julialang.org/badges/ChainMap_0.5.svg
[pkg-0.5_url]: http://pkg.julialang.org/?pkg=ChainMap
