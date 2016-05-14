# ChainMap

[![ChainMap](http://pkg.julialang.org/badges/ChainMap_0.4.svg)](http://pkg.julialang.org/?pkg=ChainMap)
[![ChainMap](http://pkg.julialang.org/badges/ChainMap_0.5.svg)](http://pkg.julialang.org/?pkg=ChainMap)
[![Build Status](https://travis-ci.org/bramtayl/ChainMap.jl.svg?branch=master)](https://travis-ci.org/bramtayl/ChainMap.jl)
[![Coverage Status](https://coveralls.io/repos/bramtayl/ChainMap.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/bramtayl/ChainMap.jl?branch=master)
[![Build status](https://ci.appveyor.com/api/projects/status/github/bramtayl/ChainMap.jl?svg=true&branch=master)](https://ci.appveyor.com/project/bramtayl/chainmap-jl/branch/master)

This package attempts to integrate mapping and chaining.
The chaining code owes heavily to one-more-minute/Lazy.jl.
Here is a short example to illustrate the different kind of things you can do with this package.

```{julia}
@> begin
 [1, 2]
 (_, _)
 @.>> begin
   +(_...)
   -(1)
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

Here is a short list of exported objects and what they do. See docstrings for
more information about each function.

    Macro    Standard evaluation version    Description
    ----------------------------------------------------------------------------
    @>       chain                          Chain functions
    @f       lambda                         Chain then turn into a lambda
    @fs      lambda(multi = true)           Chain then turn into a lambda that gathers arguments into a tuple
    @.>      chain_map                      Chain then map over an object
    @.>>     chain_map(multi = true)        Chain then map over several objects in a tuple
