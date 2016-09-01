type AnnotatedLine
    line::Expr
    expr
end

function annotate(args)
    odd_indices = 1:2:length(args)
    args_split = [AnnotatedLine(args[i], args[i+1] ) for i in odd_indices]
end

Base.convert(::Type{Expr}, a::AnnotatedLine) = Expr(:block, a.line, a.expr)
