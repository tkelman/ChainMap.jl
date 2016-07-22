chopn(s, n) = s[1:(end - n)]

function remove_suffix(f, suffix)
  f_string = string(f)
  if !(endswith(f_string, suffix))
    error("f must end in $suffix")
  end
  Symbol(chopn(f_string, length(suffix)))
end

function nonstandard1(f)
  quote
    macro $f(args...)
      esc($f(args...) )
    end
  end
end

function multiblock1(f)
  f_chop = remove_suffix(f, "1")
  quote
    function $f_chop(fs...)
      Expr(:block, map($f, fs)...)
    end
  end
end

function safe1(f)
  f_chop = remove_suffix(f, "!")
  quote
    $f_chop(x, args...; kwargs...) =
      $f(copy(x), args...; kwargs...)
  end
end
