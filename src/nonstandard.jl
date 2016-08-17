function nonstandard1(f)
  symbol_f = Symbol("@" * string(f) )
  macro_f = Expr(:quote, Expr(:macrocall, symbol_f))
  string_f = "See documentation of [`$f`](@ref)"
  quote
      macro $f(args...)
          esc($f(args...) )
      end
      @doc $string_f $macro_f
  end
end

export nonstandard
"""
    @nonstandard(fs...)

Will create a nonstandard evaluation macro for each of the `fs` functions.

Each function should be a function that takes and returns expressions. The
nonstandard macro will have the same name but will take in code, not
expressions, and will evaluate the result locally when the macro is called. Will
write a docstring for the nonstandard version pointing to the documentation of
the standard version.

# Examples
```julia
binaryfun(a, b, c) = :(\$b(\$a, \$c))
chainback(a, b, c) = :(\$c(\$b, \$a))

@nonstandard binaryfun chainback

@test vcat(1, 2) == @binaryfun 1 vcat 2
@test vcat(3, 2) == @chainback 2 3 vcat

"See documentation of [`binaryfun`](@ref)" ==
    @chain (@doc @binaryfun) string chomp

```
"""
nonstandard(fs...) = Expr(:block, map(nonstandard1, fs)...)

export @nonstandard
eval(nonstandard(:nonstandard))
