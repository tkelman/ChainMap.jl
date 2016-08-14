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
"Docstring for @binaryfun"
binaryfun(a, b, c) = :(\$b(\$a, \$c))

chainback(a, b, c) = :(\$c(\$b, \$a))

@nonstandard binaryfun chainback

@test (@binaryfun 1 vcat 2) == vcat(1, 2)
@test (@chainback 2 3 vcat) == vcat(3, 2)
```
"""
nonstandard(fs...) = Expr(:block, map(nonstandard1, fs)...)

function break_up_block(e)
     if MacroTools.isexpr(e, :block)
         break_up_blocks(MacroTools.rmlines(e).args...)
     elseif MacroTools.isexpr(e, :(=))
         Expr(:kw, e.args...)
     else
         e
     end
 end

break_up_blocks(es...) = vcat(map(break_up_block, es)...)

"""
   @push_block(es...)

Will break up any begin blocks in `es`, create keyword arguments from
assignments, and feed them to `push`

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

@test push_test == push(collect_arguments(1), 2, a = 3)
```
"""
push_block(es...) = Expr(:call, :push, break_up_blocks(es...)...)

"""
    @arguments_block(es...)

Will break up any begin blocks in `es` into lines, create keyword arguments from
assignments, and feed all arguments to `collect_arguments`

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
     Expr(:call, :collect_arguments, break_up_blocks(es...)...)

export @nonstandard
eval(nonstandard(:nonstandard))

export @chain, @unweave, @lazy_call, @push_block, @arguments_block
@nonstandard chain unweave lazy_call push_block arguments_block
