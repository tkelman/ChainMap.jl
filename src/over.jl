bitnot = ~

replace_record!(e, d) = (e, d)
function replace_record!(e::Expr, d)
  if MacroTools.@capture e begin ~(key_) end
    if !(haskey(d, key))
      d[key] =
        MacroTools.isexpr(key, :...) ?
        Expr(:..., gensym() ) : gensym()
    end
    e = d[key]
  else
    replace_record!(e.head, d)
    map!(e -> replace_record!(e, d)[1], e.args)
  end
  (e, d)
end

function over!(e)
  d = Dict()
  replace_record!(e, d)

  if length(d) == 0
    return e
  end

  dotted = filter((k, v) -> MacroTools.isexpr(k, :...), d)
  undotted = filter((k, v) -> !(MacroTools.isexpr(k, :...)), d)

  if length(dotted) > 1
    error("Cannot map over more than one splatted argument")
  end

  Expr(:call, :broadcast,
       Expr(:->,
            Expr(:tuple,
                 values(undotted)... ,
                 values(dotted)...) ,
            e),
       keys(undotted)... ,
       keys(dotted)... )
end

over(e) = e
over(e::Expr) = over!(copy(e))
