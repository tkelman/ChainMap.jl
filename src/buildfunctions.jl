chopn(s, n) = s[1:(end - n)]

function remove_suffix(suffixed::AbstractString, suffix::AbstractString)
  if !(endswith(suffixed, suffix))
    error("suffixed must end in suffix")
  end
  chopn(suffixed, length(suffix))
end

function nonstandard1(f)
  quote
    macro $f(args...)
      esc($f(args...) )
    end
  end
end

function multiblock1(f)
  f_chop = Symbol(remove_suffix(string(f), "1"))
  quote
    function $f_chop(fs...)
      Expr(:block, map($f, fs)...)
    end
  end
end

function safe1(f)
  f_chop = Symbol(remove_suffix(string(f), "!"))
  quote
    $f_chop(x, args...; kwargs...) =
      $f(copy(x), args...; kwargs...)
  end
end

make_aliases() =
  quote
    c = ChainMap.chain
    o = ChainMap.over
    l = ChainMap.lambda
    ChainMap.@nonstandard c o l
  end
