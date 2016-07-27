# ChainMap.jl Documentation

This package attempts to integrate mapping and chaining. The chaining code owes
heavily to one-more-minute/Lazy.jl.

## Read Me

### Chaining

Here is a short example to illustrate the chaining mechanism.

```{julia}
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

### Argument Building

There is another mechanism of argument storage. This is conceptually the
inverse of chaining. Here is an example:

```{julia}
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

### Macro generation

There are several macros that create new functions/macros based on existing
functions included: `@nonstandard`, `@safe`, and `@multiblock`. See docstrings
for more information. Note that these functions were used to generate the
package itself. Standard evaluation versions exist for all exported macros.

### Aliasing

If you want shorter versions of the chaining functions for convenience, run the
code below.

```{julia}
c = ChainMap.chain
o = ChainMap.over
l = ChainMap.lambda
@nonstandard c o l
```

This will create, for example, the `@c` macro as identical to `@chain`.

## Index of exports

```@index
```

```@autodocs
Modules = [ChainMap]
```
