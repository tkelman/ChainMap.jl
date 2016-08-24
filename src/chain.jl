type AnnotatedLine
    line::Expr
    expr
end

function annotate(args)
    odd_indices = 1:2:length(args)
    args_split = [AnnotatedLine(args[i], args[i+1] ) for i in odd_indices]
end

Base.convert(::Type{Expr}, a::AnnotatedLine) = Expr(:block, a.line, a.expr)

is_(e) =
    if MacroTools.isexpr(e, :parameters, :..., :kw, :~)
        contains_(e)
    else
        e == :_
    end

contains_(e) = any(map(is_, e.args) )

function insert_(e::Expr)
    # first part needed because of MacroTools unblocking
    if e.head == :block || contains_(e)
        return e
    end

    MacroTools.@match e begin
      @a_(b__) => Expr(:macrocall, a, :_, b...)
      a_(b__) => Expr(:call, a, :_, b...)
      a_ => a
    end
end

insert_(a::AnnotatedLine) = AnnotatedLine(a.line, insert_(a.expr))

expose(tail::Expr, head) = Expr(:let, tail, Expr(:(=), :_, head))

expose(tail::AnnotatedLine, head) =
    AnnotatedLine(tail.line, expose(tail.expr, convert(Expr, head)))

export chain
"""
    @chain insert_this into_that::Expr

`@chain` always reinterprets `\_` in `into_that` as `insert_this`.

If

- `into_that` can be recognized as a function call or a macro call, and
- bare `_` is not a positional argument, assigned to a keyword, or splatted
    before or after `;`

`_` will be inserted as the first argument to `into_that`.

If `into_that` is a closure, it will be called on `insert_this`.

To prevent insertion into the first argument, but still reinterpret `_`,
wrap `into_that` in a `begin` block.

# Examples
```julia
@test vcat(1, 2) == @chain 1 vcat(2)

@test vcat(2, 1) == @chain 1 vcat(2, _)

@test vcat(3, 2, 1) == @chain (2, 1) vcat(3, _...)

@test 0 == @chain 1 begin -(3, 2 + _) end

keyword_test(; keyword_arguments...) = keyword_arguments

@test keyword_test(a = 1) == @chain 1 keyword_test(a = _)

@test keyword_test(b = 2, a = 1) ==
    @chain keyword_test(a = 1) keyword_test(b = 2; _...)
```
"""
chain(insert_this, into_that::Expr) = expose(insert_(into_that), insert_this)

"""
    @chain on_that call_this::Symbol

Call `call_this` on `on_that`

# Examples
```julia
@test vcat(1) == @chain 1 vcat
```
"""
chain(on_that, call_this::Symbol) = :($call_this($on_that))

chain(head, tail::AnnotatedLine) =
    if typeof(tail.expr) <: Expr
        expose(insert_(tail), head)
    else
        Expr(:call, convert(Expr, tail), convert(Expr, head))
    end

"""
    @chain es...

Reduce `@chain` over `es`

# Examples
```julia
@test ( @chain 1 vcat(2) vcat(3) ) ==
    @chain ( @chain 1 vcat(2) ) vcat(3)
```
"""
chain(es...) = foldl(chain, es)

"""
    @chain e

Separate single begin blocks out into lines and recur. Return single non-blocks.

# Examples
```julia
@test 1 == @chain 1

chain_block = @chain begin
    1
    vcat
    vcat(2)
end

@test chain_block == @chain 1 vcat(2)
```
"""
chain(e) =
    if MacroTools.isexpr(e, :block)
        convert(Expr, chain(annotate(e.args)...) )
    else
        e
    end

@nonstandard chain
export @chain

export lambda
"""
    @lambda(es...)

[`chain`](@ref) together `(_, es...)`, then convert to an anonymous function with _ as
the input variable.

# Examples
```julia
lambda_function = @lambda vcat(2) vcat(3)
@test lambda_function(1) == vcat(1, 2, 3)

lambda_function_2 = @lambda -(_, 1)
@test lambda_function_2(2) == 1
```
"""
lambda(es...) = Expr(:->, :_, chain(:_, es...))

@nonstandard lambda
export @lambda
