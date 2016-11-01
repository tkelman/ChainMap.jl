"""
    map_expression(e, f)

If `e` is an expression, map `f` over the arguments in `e`.
"""
map_expression(e, f) = e
map_expression(e::Expr, f) = Expr(e.head, map(f, e.args)...)
