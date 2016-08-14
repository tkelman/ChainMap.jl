function insert_(e)
    # first part needed because of MacroTools unblocking
    if e.head == :block || :_ in e.args || Expr(:..., :_) in e.args
        return e
    end

    MacroTools.@match e begin
      @a_(b__) => Expr(:macrocall, a, :_, b...)
      a_(b__) => :( $a( _, $( b... ) ) )
      a_ => a
    end
end

expose(tail, head) = :(let _ = $head; $tail; end)

"""
    @chain head tail::Expr

`@chain` always reinterprets `\_` in `tail` as `head`.

If

- tail can be recognized as a function call or a macro call, and
- neither bare `\_` nor `\_...` is a positional argument to `tail`

`_` will be inserted as the first argument to `tail`.

To prevent insertion into the first argument, but still reinterpret `_`,
wrap `tail` in a `begin` block.

# Examples
```julia
@test ( @chain 1 vcat(2) ) ==
      vcat(1, 2)

@test ( @chain 1 vcat(2, _) ) ==
      vcat(2, 1)

@test ( @chain (2, 1) vcat(3, _...) ) ==
      vcat(3, 2, 1)

@test ( @chain 1 begin -(3, 2 + _) end ) == 0
```
"""
chain(head, tail::Expr) = expose(insert_(tail), head)

"""
    @chain head tail

Call `tail` on `head`

# Examples
```julia
@test (@chain 1 vcat) == vcat(1)
```
"""
chain(head, tail) = :($tail($head))

"""
    @chain e::Expr

Separate single begin blocks out into lines and recur. Throws an error if `e` is not
a begin block.

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
