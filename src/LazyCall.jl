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

"""
    Arguments(positional::Tuple, keyword::Vector)

Convert `keyword` to a `Dict` before creating an [`Arguments`](@ref)
type.
"""
Arguments(positional::Tuple, keyword::Vector) =
    @chain keyword Dict Arguments(positional, _)

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
    merge(collect_arguments(4, a = 5, c = 6) )
end

@test merge_test == collect_arguments(1, 4, a = 5, b = 3, c = 6)
```
"""
function Base.merge(a::Arguments, b::Arguments)
    positional = (a.positional..., b.positional...)
    @chain a.keyword merge(b.keyword) Arguments(positional, _)
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
    push(4, a = 5, c = 6)
end

@test push_test == collect_arguments(1, 4, a = 5, b = 3, c = 6)
```
"""
push(a::Arguments, positional...; keyword...) =
  @chain positional Arguments(keyword) merge(a, _)

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
    unshift(1)
end

@test unshift_test == collect_arguments(1, 2, a = 3)
```
"""
unshift(a::Arguments, positional...) =
    @chain positional Arguments([]) merge(a)

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
collect_arguments(positional...; keyword...) =
    @chain positional Arguments(keyword)

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
collect_call(f, positional...; keyword...) =
    @chain positional Arguments(keyword) LazyCall(f)

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
    unshift(vcat)
    collect_arguments(map)
    run
end

@test run_test == map(vcat, [1, 2], [3, 4])
```
"""
Base.run(a::Arguments) = @chain a run(run)

"""
     run(l::LazyCall)

Call `l.function_call` on the [`Arguments`](@ref) in `l.arguments`

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
Base.run(l::LazyCall) = @chain l.arguments run(l.function_call)

"""
     run(a::Arguments, f::Function)

Call `f` on the [`Arguments`](@ref) in `a`

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
Base.run(a::Arguments, f::Function) =
    @chain a.keyword collect f(a.positional...; _...)

"""
     run(l::LazyCall, f::Function)

Insert `l.function` as the first positional argument in
`l.arguments`, the standard position for functional programming,
then call `f` on the result.

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
    @chain l.arguments unshift(l.function_call) run(f)

export lazy_call
"""
    @lazy_call(e)

Will break apart a function call into a [`LazyCall`](@ref) object.
Cannot handle keyword arguments at the moment.

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

@nonstandard lazy_call
export @lazy_call

function break_up_block(e)
     if @chain e MacroTools.isexpr(:block)
         @chain e MacroTools.rmlines() _.args break_up_blocks(_...)
     elseif @chain e MacroTools.isexpr(:(=))
         @chain :kw Expr(e.args...)
     else
         e
     end
 end

break_up_blocks(es...) = @chain es map(break_up_block, _) vcat(_...)

export push_block
"""
   @push_block(es...)

Will break up any begin blocks in `es`, create keyword arguments from
assignments, and feed them to [`push`](@ref)

# Examples
```julia
push_test = @chain begin
    1
    collect_arguments
    @push_block begin
        2
        a = 3
    end
end

@test push_test == @chain 1 collect_arguments push(2, a = 3)
```
"""
push_block(es...) = @chain es break_up_blocks(_...) Expr(:call, :push, _...)

@nonstandard push_block
export @push_block

export arguments_block
"""
    @arguments_block(es...)

Will break up any begin blocks in `es` into lines, create keyword arguments from
assignments, and feed all arguments to [`collect_arguments`](@ref)

# Examples
```julia
arguments_test = @chain begin
    1
    @arguments_block begin
        2
        a = 3
    end
end

@test arguments_test == collect_arguments(1, 2, a = 3)
```
"""
arguments_block(es...) =
     @chain es break_up_blocks(_...) Expr(:call, :collect_arguments, _...)

@nonstandard arguments_block
export @arguments_block
