# ChainMap

[![Build Status](https://travis-ci.org/bramtayl/ChainMap.jl.svg?branch=master)](https://travis-ci.org/bramtayl/ChainMap.jl)
[![Coverage Status](https://coveralls.io/repos/bramtayl/ChainMap.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/bramtayl/ChainMap.jl?branch=master)

This package attempts to integrate mapping and chaining.
The chaining code owes heavily to one-more-minute/Lazy.jl.
Here is a short example to illustrate the different kind of things you can do with this package.

```{julia}
@chain begin
  [1, 2]
  -(1)
  (_, _)
  map_all(+)
  @chain_map begin
    -(1)
    float
    ^(2, _)
  end
  begin
    a = _ - 1
    b = _ + 1
    [a, b]
  end
  sum
end
```

Here is a short list of exported objects and what they do:

    Function        Description
    ---------------------------------------------------------
    @chain          Chain functions
    @lambda         Chain functions, then turn into a lambda
    @chain          Chain functions, then map over an object
    chain           Standard evaluation version of @chain
    lambda          Standard evaluation version of @lambda
    chain_map       Standard evaluation version of @chain_map
    map_all         Chain friendly version of broadcast
