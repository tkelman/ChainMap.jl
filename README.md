# ChainMap.jl

This package attempts to integrate mapping and chaining. The chaining code owes
heavily to one-more-minute/Lazy.jl.

| **Documentation**                                                               | **PackageEvaluator**                                            | **Build Status**                                                                                |
|:-------------------------------------------------------------------------------:|:---------------------------------------------------------------:|:-----------------------------------------------------------------------------------------------:|
| [![][docs-stable_image]][docs-stable_url] [![][docs-latest_image]][docs-latest_url] | [![][pkg-0.4_image]][pkg-0.4_url] [![][pkg-0.5_image]][pkg-0.5_url] | [![][travis_image]][travis_url] [![][appveyor_image]][appveyor_url] [![][codecov_image]][codecov_url] |

## Documentation

- [**STABLE**][docs-stable_url] &mdash; **most recently tagged version of the documentation.**
- [**LATEST**][docs-latest_url] &mdash; *in-development version of the documentation.*

## Examples

### Example 1

```julia
A = [1, 2]
B = [3, 4]

fancy = @chain begin
    A
    map(x -> x + 1, _)
    begin @unweave vcat(~_, ~B, ~[5, 6] ) end
    run(map)
end

boring = map((a, b, c) -> vcat(a, b, c), map(x -> x + 1, A), B, [5, 6])

@test fancy == boring
```

### Example 2

```julia
along() = "dummy function; could be a fancy view some day"

Base.run(A::AbstractArray,
         map_call::typeof(map), map_function::Function,
         along_call::LazyCall{typeof(along)},
         reduce_call::typeof(reduce), reduce_function::Function) =
    mapreducedim(map_function, reduce_function, A,
                 along_call.arguments.positional[1] )

fancy = @chain begin
    [1, 2, 3, 4]
    reshape(2, 2)
    @arguments_block begin
        map
        x -> x + 1
        @lazy_call along(1)
        reduce
        +
    end
    run
end

boring = mapreducedim(x -> x + 1, +, reshape([1, 2, 3, 4], 2, 2), 1)

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
