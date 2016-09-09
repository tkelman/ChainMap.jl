export Arguments
"""
    type Arguments
        positional::Tuple
        keyword::Dict{Symbol, Any}
    end

Will store positional and keyword arguments for later use. Create
with [`collect_arguments`](@ref). You can also [`merge`](@ref) two
`Arguments`, [`push`](@ref) or [`unshift`](@ref) in new
arguments, and run with [`run`](@ref).
"""
type Arguments
  positional::Tuple
  keyword::Dict{Symbol, Any}
end

export LazyCall
"""
    type LazyCall{T <: Function}
        arguments::Arguments
        function_call::T
    end

Will store a function along with its arguments for later use. Create
with [`collect_call`](@ref) and run with [`run`](@ref)
"""
type LazyCall{T <: Function}
    arguments::Arguments
    function_call::T
end

"""
    merge(a::Arguments, b::Arguments)

Merge two [`Arguments`](@ref) types.

Positional arguments are added at the end, and new keyword arguments
are added to old keyword arguments, or, if the keys match, overwrite
them.

# Examples
```julia
merge_test = @chain begin
    collect_arguments(1, a = 2, b = 3)
    merge(_, collect_arguments(4, a = 5, c = 6) )
end

@test merge_test == collect_arguments(1, 4, a = 5, b = 3, c = 6)
```
"""
function Base.merge(a::Arguments, b::Arguments)
    positional = (a.positional..., b.positional...)
    keyword = merge(a.keyword, b.keyword)
    Arguments(positional, keyword)
end

"""
    merge(lazy_call::LazyCall, arguments::Arguments)

`merge` `arguments` into the `arguments` of `lazy_call`.

# Examples
```julia
merge_test = @chain begin
    collect_arguments([1, 2])
    unshift(_, vcat)
    LazyCall(_, map)
    merge(_, collect_arguments([3, 4]) )
    run
end

@test merge_test == [[1, 3], [2, 4]]
```
"""
Base.merge(lazy_call::LazyCall, arguments::Arguments) = @chain begin
    lazy_call.arguments
    merge(_, arguments)
    LazyCall(_, lazy_call.function_call)
end

export push
"""
    push(arguments::Arguments, positional...; keyword...)

Add positional and keyword arguments to an already existing
[`Arguments`](@ref) type.

Positional arguments are added at the end, and new keyword arguments
are added to old keyword arguments, or, if the keys match, overwrite
them.

# Examples
```julia
push_test = @chain begin
    collect_arguments(1, a = 2, b = 3)
    push(_, 4, a = 5, c = 6)
end

@test push_test == collect_arguments(1, 4, a = 5, b = 3, c = 6)
```
"""
push(a::Arguments, positional...; keyword...) =
  @chain begin
      keyword
      Dict
      Arguments(positional, _)
      merge(a, _)
  end

"""
    push(lazy_call::LazyCall, positional...; keyword...)

`push` to the `arguments` of `lazy_call`.

# Examples
```julia
push_test = @chain begin
    collect_arguments([1, 2])
    unshift(_, vcat)
    LazyCall(_, map)
    push(_, [3, 4])
    run
end

@test push_test == [[1, 3], [2, 4]]
```
"""
push(lazy_call::LazyCall, positional...; keyword...) = @chain begin
    lazy_call.arguments
    push(_, positional...; keyword...)
    LazyCall(_, lazy_call.function_call)
end

export unshift
"""
    unshift(arguments::Arguments, positional...)

Add positional arguments to an already existing [`Arguments`](@ref)
type.

New arguments are added at the start.

# Examples
```julia
unshift_test = @chain begin
    collect_arguments(2, a = 3)
    unshift(_, 1)
end

@test unshift_test == collect_arguments(1, 2, a = 3)
```
"""
unshift(a::Arguments, positional...) = @chain begin
    positional
    Arguments(_, Dict() )
    merge(_, a)
end

"""
    unshift(lazy_call::LazyCall, positional...)

`unshift` to the `arguments` of `lazy_call`.

# Examples
```julia
unshift_test = @chain begin
    collect_arguments([1, 2], [3, 4])
    LazyCall(_, map)
    unshift(_, vcat)
    run
end

@test unshift_test == [[1, 3], [2, 4]]
```
"""
unshift(lazy_call::LazyCall, positional...) = @chain begin
    lazy_call.arguments
    unshift(_, positional...)
    LazyCall(_, lazy_call.function_call)
end

export collect_arguments
"""
    collect_arguments(positional...; keyword...)

Easy way to build an [`Arguments`](@ref) type.

# Examples
```julia
a = collect_arguments(1, 2, a = 3, b = 4)
@test a.positional == (1, 2)
@test a.keyword == Dict{Symbol, Any}(:a => 3, :b => 4)
```
"""
collect_arguments(positional...; keyword...) = @chain begin
    keyword
    Dict
    Arguments(positional, _)
end

export collect_call
"""
    collect_call(f::Function, positional...; keyword...)

Easy way to build a [`LazyCall`](@ref) type.

# Examples
```julia
l = collect_call(vcat, [1, 2], [3, 4])
@test l.function_call == vcat
@test l.arguments == collect_arguments([1, 2], [3, 4])
```
"""
collect_call(f, positional...; keyword...) = @chain begin
    keyword
    Dict
    Arguments(positional, _)
    LazyCall(_, f)
end

import Base.==

==(a::Arguments, b::Arguments) =
    (a.positional == b.positional) && (a.keyword == b.keyword)

==(a::LazyCall, b::LazyCall) =
    (a.function_call == b.function_call) && (a.arguments == b.arguments)

export run
"""
     run(a::Arguments)

Call `run` on the [`Arguments`](@ref) in `a`

# Examples
```julia
run_test = @chain begin
    collect_arguments([1, 2], [3, 4])
    unshift(_, vcat)
    collect_arguments(_, map)
    run
end

@test run_test == map(vcat, [1, 2], [3, 4])
```
"""
Base.run(a::Arguments) = run(a, run)

"""
     run(l::LazyCall)

Call `l.function_call` on the [`Arguments`](@ref) in `l.arguments`

# Examples
```julia
run_test = @chain begin
    collect_arguments([1, 2], [3, 4])
    unshift(_, vcat)
    LazyCall(_, map)
    run
end

@test run_test == map(vcat, [1, 2], [3, 4])
```
"""
Base.run(l::LazyCall) = run(l.arguments, l.function_call)

"""
     run(a::Arguments, f::Function)

Call `f` on the [`Arguments`](@ref) in `a`

# Examples
```julia
run_test = @chain begin
    collect_arguments([1, 2], [3, 4])
    unshift(_, vcat)
    run(_, map)
end

@test run_test == map(vcat, [1, 2], [3, 4])
```
"""
Base.run(a::Arguments, f::Function) = f(a.positional...; a.keyword...)

"""
     run(l::LazyCall, f::Function)

Insert `l.function_call` as the first positional argument in
`l.arguments`, the standard position for functional programming,
then `run` `f` on the result.

# Examples
```julia
run_test = @chain begin
    collect_arguments([1, 2], [3,4])
    LazyCall(_, vcat)
    run(_, map)
end

@test run_test == map(vcat, [1, 2], [3, 4])
```
"""
Base.run(l::LazyCall, f::Function) = @chain begin
    l.arguments
    unshift(_, l.function_call)
    run(_, f)
end

export lazy_call
"""
    @lazy_call(e)

Will break apart a function call into a [`LazyCall`](@ref) object.

# Examples
```julia
test_function(arguments...; keyword_arguments...) =
    (arguments, keyword_arguments)

@test ( @lazy_call test_function(1, 2, a= 3) ) ==
    collect_call(test_function, 1, 2, a = 3)
```
"""
lazy_call(e) =
    MacroTools.@match e begin
        a_(b__) => Expr(:call, :collect_call, a, b...)
        a_ => a
    end

@nonstandard lazy_call
export @lazy_call
