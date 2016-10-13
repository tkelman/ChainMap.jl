type AnnotatedLine
    line::Expr
    expression
end

function annotate(arguments)
    odd_indices = 1:2:length(arguments)
    map(index -> AnnotatedLine(arguments[index], arguments[index + 1] ),
        odd_indices)
end

Base.convert(::Type{Expr}, a::AnnotatedLine) =
    Expr(:block, a.line, a.expression)
