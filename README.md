# ChainMap.jl

This package attempts to integrate mapping and chaining. The chaining code owes
heavily to one-more-minute/Lazy.jl.

## Badges

### Documentation

[![][docs-stable_image]][docs-stable_url] [![][docs-latest_image]][docs-latest_url]

### Build Status

[![][travis_image]][travis_url] [![][appveyor_image]][appveyor_url]

### Package Evaluator

[![][pkg-0.4_image]][pkg-0.4_url] [![][pkg-0.5_image]][pkg-0.5_url]

### Coverage

[![][coveralls_image]][coveralls_url] [![][codecov_image]][codecov_url]

[docs-latest_image]: https://img.shields.io/badge/docs-latest-blue.svg
[docs-latest_url]: https://bramtayl.github.io/ChainMap.jl/latest

[docs-stable_image]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable_url]: https://bramtayl.github.io/ChainMap.jl/stable

[travis_image]: https://travis-ci.org/bramtayl/ChainMap.jl.svg?branch=master
[travis_url]: https://travis-ci.org/bramtayl/ChainMap.jl

[appveyor_image]: https://ci.appveyor.com/api/projects/status/github/bramtayl/ChainMap.jl?svg=true&branch=master
[appveyor_url]: https://ci.appveyor.com/project/bramtayl/chainmap-jl/branch/master

[coveralls_image]: https://coveralls.io/repos/bramtayl/ChainMap.jl/badge.svg?branch=master&service=github
[coveralls_url]: https://coveralls.io/github/bramtayl/ChainMap.jl?branch=master

[codecov_image]: https://codecov.io/github/bramtayl/ChainMap.jl/coverage.svg?branch=master
[codecov_url]: https://codecov.io/github/bramtayl/ChainMap.jl?branch=master

[issues_url]: https://github.com/bramtayl/ChainMap.jl/issues

[pkg-0.4_image]: http://pkg.julialang.org/badges/ChainMap_0.4.svg
[pkg-0.4_url]: http://pkg.julialang.org/?pkg=ChainMap

[pkg-0.5_image]: http://pkg.julialang.org/badges/ChainMap_0.5.svg
[pkg-0.5_url]: http://pkg.julialang.org/?pkg=ChainMap

## Example 1

How fast can we build a non-standard evaluation transform function?

A vanilla transform function.
```julia
function transform(d; keyword_arguments...)
    d_new = copy(d)
    for (key, value) in keyword_arguments
        d_new[key] = value
    end
    d_new
end
```

A function which combines three macros in `ChainMap`: `chain`, `with`, and
`unweave`.
```julia
all_in_one(e) = @chain begin
    e
    chain(_)
    with(_)
    unweave(:broadcast, _)
end
```

Run `all_in_one` on the values of a keyword argument.
```julia
transform_into(e) = MacroTools.@match e begin
    (key_ = value_) => @chain begin
        value
        all_in_one(_)
        Expr(:kw, key, _)
    end
end
```

`map` `transform_into` over `keyword_arguments`, then `transform`. Don't forget
a non-standard evaluation version!
```julia
transform_with(d, keyword_arguments...) = @chain begin
    keyword_arguments
    map(transform_into, _)
    Expr(:call, :transform, d, _...)
end

@nonstandard transform_with
```

Let's see if it works!

```julia
a = ["one", "two"]
result = @chain begin
    DataFrames.DataFrame(b = [1, 2], c = ["I", "II"])
    @transform_with(_, d = begin
        :b
        sum(_)
        string(_)
        *(~a, " ", _, " ", ~:c)
    end)
end

@test result[:d] == ["one 3 I", "two 3 II"]
```

Thanks to DataFramesMeta.jl for the inspiration for this example.

### Example 2

Here, define a custom way to combine several function calls into one more
efficient one.

```julia
along() = "dummy function; could be a fancy view some day"

Base.run(A::AbstractArray,
         map_call::typeof(map), map_function::Function,
         along_call::LazyCall{typeof(along)},
         reduce_call::typeof(reduce), reduce_function::Function) =
    mapreducedim(map_function, reduce_function, A,
                 along_call.arguments.positional[1] )

```

Test it out!

```julia
fancy = @chain begin
    [1, 2, 3, 4]
    reshape(_, 2, 2)
    collect_arguments(
        _,
        map,
        _ -> -(_, 1),
        @lazy_call( along(1) ),
        reduce,
        +)
    run(_)
end

boring = mapreducedim(x -> x - 1, +, reshape([1, 2, 3, 4], 2, 2), 1)

@test fancy == boring
```
