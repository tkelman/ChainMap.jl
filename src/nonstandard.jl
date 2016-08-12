function nonstandard1(f)
  macro_f = Expr(:quote, Expr(:macrocall, Symbol("@" * string(f))))
  quote
      macro $f(args...)
          esc($f(args...) )
      end
      @doc (@doc $f) $macro_f
  end
end

"""
   @nonstandard(fs...)
Will create a nonstandard evaluation macro for each of the fs functions.

Each function should be a function that takes and returns expressions. The
nonstandard macro will have the same name but will take in code, not
expressions, and will evaluate the result locally when the macro is called. Will
copy over the docstrings from the standard version to the nonstandard version.
#Examples
```julia
binaryfun(a, b, c) = :(\$b(\$a, \$c))
chainback(a, b, c) = :(\$c(\$b, \$a))
@nonstandard binaryfun chainback
@test (@binaryfun 1 vcat 2) == vcat(1, 2)
@test (@chainback 2 3 vcat) == vcat(3, 2)
```
"""
nonstandard(fs...) = Expr(:block, map(nonstandard1, fs)...)

export @nonstandard
eval(nonstandard(:nonstandard))

export @chain, @unweave, @lazy_call
@nonstandard chain unweave lazy_call
