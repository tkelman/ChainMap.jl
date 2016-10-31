"""
function_call = :binary_function
nonstandard(function_call)
"""
function nonstandard1(function_call::Symbol)
  macro_symbol = Symbol("@" * string(function_call) )
  macro_quote = Expr(:quote, Expr(:macrocall, macro_symbol))
  doc_string = "See documentation of [`$function_call`](@ref)"
  quote
      macro $function_call(args...)
          esc($function_call(args...) )
      end
      @doc $doc_string $macro_quote
  end
end

export nonstandard
"""
    @nonstandard(function_calls...)

Will create a nonstandard evaluation macro for each of the `function_calls`.

Each function should be a function that takes and returns expressions. The
nonstandard macro will have the same name. Will write a docstring for the
nonstandard version pointing to the documentation of the standard version.

# Examples
```julia
@chain begin

    nonstandard(:binary_function, :chain_back)

    binary_function(a, b, c) = Expr(:call, b, a, c)
    chain_back(a, b, c) = Expr(:call, c, b, a)

    @nonstandard binary_function chain_back

    @test vcat(1, 2) == @binary_function 1 vcat 2
    @test vcat(3, 2) == @chain_back 2 3 vcat

    @test "See documentation of [`binary_function`](@ref)" == begin
        (@doc @binary_function)
        string
        chomp
    end

end

```
"""
nonstandard(function_calls...) =
    Expr(:block, map(nonstandard1, function_calls)...)

export @nonstandard
eval(nonstandard(:nonstandard))
