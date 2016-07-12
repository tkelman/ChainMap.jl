export @safe, @allsafe, safe

"""
    @safe(fs...)

Defines a new version of mutate-in-place functions like `push!` that copies the
first position argument before processing. The new function will have a name
without !, like `push`. Can take multiple functions.
"""
macro safe(fs...)
  @c fs safe(_...) esc
end

"""
    @allsafe(fs...)

Same as `@safe`, except creates copies of all arguments
"""
macro allsafe(fs...)
  @c fs safe(_...; onearg = false) esc
end

function safe_single(f::Symbol; onearg = true)
  f_string = string(f)
  if @c f_string endswith("!") !
    error("Function must end in !")
  end
  f_chop = @c f_string chop symbol

  onearg ?
    :( $f_chop(x, args...; kwargs...) = $f(copy(x), args...; kwargs...) ) :
    :( $f_chop(args...; kwargs...) =
         $f(map(copy, args)...;
                map(kw -> (kw[1], copy(kw[2]) ), kwargs)...) )
end

"""
    safe(fs...; onearg = true)

If `onearg = true`, standard evaluation version of `@safe`. Else, standard
evaluation version of `@allsafe`.
"""
safe(fs...; onearg = true) = @c begin
  fs
  map(x -> safe_single(x, onearg = onearg), _)
  Expr(:block, _...)
end
