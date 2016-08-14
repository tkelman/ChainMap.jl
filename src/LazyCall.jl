export Arguments
"""
    type Arguments
        positional::Tuple
        keyword::Dict{Symbol, Any}
    end

Will store positional and keyword arguments for later use.
"""
type Arguments
  positional::Tuple
  keyword::Dict{Symbol, Any}
end

"""
    Arguments(positional::Tuple, keyword::Vector)

Convert `keyword` to a `Dict` before creating Arguments type.
"""
Arguments(positional::Tuple, keyword::Vector) =
    Arguments(positional, Dict(keyword))

"""
    merge(a::Arguments, b::Arguments)

Merge two `Arguments` types.

Positional arguments are added at the end, and new keyword arguments are added
to old keyword arguments, or, if the keys match, overwrite them.

# Examples
```julia
merge_test = @chain begin
    collect_arguments(1, a = 2, b = 3)
    merge(collect_arguments(4, a = 5, c = 6) )
end

@test merge_test == collect_arguments(1, 4, a = 5, b = 3, c = 6)
```
"""
function Base.merge(a::Arguments, b::Arguments)
    Arguments((a.positional..., b.positional...),
              merge(a.keyword, b.keyword))
end

export push
"""
    push(arguments::Arguments, positional...; keyword...)

Add positional and keyword arguments to an already existing `Arguments` type.

Positional arguments are added at the end, and new keyword arguments are added
to old keyword arguments, or, if the keys match, overwrite them.

# Examples
```julia
push_test = @chain begin
    collect_arguments(1, a = 2, b = 3)
    push(4, a = 5, c = 6)
end

@test push_test == collect_arguments(1, 4, a = 5, b = 3, c = 6)
```
"""
function push(a::Arguments, positional...; keyword...)
  merge(a, Arguments(positional, keyword))
end

export unshift
"""
    unshift(arguments::Arguments, positional...)

Add positional arguments to an already existing arguments type. Arguments are
added at the start.

# Examples
```julia
unshift_test = @chain begin
    collect_arguments(2, a = 3)
    unshift(1)
end

@test unshift_test == collect_arguments(1, 2, a = 3)
```
"""
function unshift(a::Arguments, positional...)
  merge(Arguments(positional, []), a)
end

export LazyCall
"""
    type LazyCall{T <: Function}
        arguments::Arguments
        function_call::T
    end

Will store a function along with its arguments for later use.
"""
type LazyCall{T <: Function}
    arguments::Arguments
    function_call::T
end

export collect_arguments
"""
    collect_arguments(positional...; keyword...)

Easy way to build an `Arguments` type.

# Examples
```julia
a = collect_arguments(1, 2, a = 3, b = 4)
@test a.positional == (1, 2)
@test a.keyword == Dict{Symbol, Any}(:a => 3, :b => 4)
```
"""
collect_arguments(positional...; keyword...) =
    Arguments(positional, keyword)

export collect_call
"""
    collect_call(f::Function, positional...; keyword...)

Easy way to build a `LazyCall` type.

# Examples
```julia
l = collect_call(vcat, [1, 2], [3, 4])
@test l.function_call == vcat
@test l.arguments == collect_arguments([1, 2], [3, 4])
```
"""
collect_call(f, positional...; keyword...) =
    LazyCall(Arguments(positional, keyword), f)

import Base.==

==(a::Arguments, b::Arguments) =
    (a.positional == b.positional) && (a.keyword == b.keyword)

==(a::LazyCall, b::LazyCall) =
    (a.function_call == b.function_call) && (a.arguments == b.arguments)

export run
"""
     run(a::Arguments)

Call `run` on the arguments in `a`

# Examples
```julia
run_test = @chain begin
    collect_arguments([1, 2], [3, 4])
    unshift(vcat)
    collect_arguments(map)
    run
end

@test run_test == map(vcat, [1, 2], [3, 4])
```
"""
Base.run(a::Arguments) = run(a, run)

"""
     run(l::LazyCall)

Call `l.function_call` on the arguments in `l.arguments`

# Examples
```julia
run_test = @chain begin
    collect_arguments([1, 2], [3, 4])
    unshift(vcat)
    LazyCall(map)
    run
end

@test run_test == map(vcat, [1, 2], [3, 4])
```
"""
Base.run(l::LazyCall) = run(l.arguments, l.function_call)

"""
     run(a::Arguments, f::Function)

Call `f` on the arguments in `a`

# Examples
```julia
run_test = @chain begin
    collect_arguments([1, 2], [3, 4])
    unshift(vcat)
    run(map)
end

@test run_test == map(vcat, [1, 2], [3, 4])
```
"""
Base.run(a::Arguments, f::Function) = f(a.positional...; collect(a.keyword)...)

"""
     run(l::LazyCall, f::Function)

Insert `l.function` as the first positional arguments in `l.arguments`,
the standard position for functional programming, then call `f` on the result.

# Examples
```julia
run_test = @chain begin
    collect_arguments([1, 2], [3,4])
    LazyCall(vcat)
    run(map)
end

@test run_test == map(vcat, [1, 2], [3, 4])
```
"""
Base.run(l::LazyCall, f::Function) =
    run(unshift(l.arguments, l.function_call), f)

"""
    @lazy_call(e)

Will break apart a function call into a `LazyCall` object. Cannot handle keyword arguments at the
moment.

# Examples
```julia
@test ( @lazy_call +(1, 2) ) == collect_call(+, 1, 2)

@test ( @lazy_call(1) ) == 1
```
"""
lazy_call(e) =
    MacroTools.@match e begin
        a_(b__) => :(collect_call($a, $(b...)))
        a_ => a
    end
