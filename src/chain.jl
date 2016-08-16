is_(e) =
    if MacroTools.isexpr(e, :parameters, :..., :kw)
        contains_(e)
    else
        e == :_
    end

contains_(e) = any(map(is_, e.args) )

function insert_(e)
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

expose(into_that, insert_this) = :(let _ = $insert_this; $into_that; end)

export chain
"""
    @chain insert_this into_that::Expr

`@chain` always reinterprets `\_` in `into_that` as `insert_this`.

If

- `into_that` can be recognized as a function call or a macro call, and
- bare `_` is not a positional argument, assigned to a keyword, or splatted
    before or after `;`

`_` will be inserted as the first argument to `into_that`.

To prevent insertion into the first argument, but still reinterpret `_`,
wrap `into_that` in a `begin` block.

# Examples
```julia
@test ( @chain 1 vcat(2) ) ==
      vcat(1, 2)

@test ( @chain 1 vcat(2, _) ) ==
      vcat(2, 1)

@test ( @chain (2, 1) vcat(3, _...) ) ==
      vcat(3, 2, 1)

@test ( @chain 1 begin -(3, 2 + _) end ) == 0

keyword_test(; keyword_arguments...) = keyword_arguments

@test (@chain 1 keyword_test(a = _)) ==
      keyword_test(a = 1)

@test (@chain keyword_test(a = 1) keyword_test(b = 2; _...) ) ==
      keyword_test(b = 2, a = 1)
```
"""
chain(insert_this, into_that::Expr) = expose(insert_(into_that), insert_this)

"""
    @chain on_that call_this

Call `call_this` on `on_that`

# Examples
```julia
@test (@chain 1 vcat) == vcat(1)
```
"""
chain(on_that, call_this) = :($call_this($on_that))

"""
    @chain e::Expr

Separate single begin blocks out into lines and recur.

Throws an error if `e` is not a begin block.

# Examples
```julia
chain_block = @chain begin
    1
    vcat(2)
end

@test chain_block == @chain 1 vcat(2)

# Cannot chain only one argument
@test_throws ErrorException ChainMap.chain(:(1 + 1))
```
"""
chain(e::Expr) =
    if e.head == :block
        chain(MacroTools.rmlines(e).args...)
    else
        error("Cannot chain only one argument")
    end

"""
    @chain es...

Reduce `@chain` over `es`

# Examples
```julia
@test ( @chain 1 vcat(2) vcat(3) ) ==
      ( @chain ( @chain 1 vcat(2) ) vcat(3) )
```
"""
chain(es...) = reduce(chain, es)

@nonstandard chain
export @chain
