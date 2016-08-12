export @chain
macro chain(es...)
    esc(ChainMap.chain(es...))
end
@doc chain :(@chain)

export @unweave
macro unweave(es...)
    esc(ChainMap.unweave(es...))
end
@doc unweave :(@unweave)

export @lazy_call
@doc lazy_call :(@lazy_call)
macro lazy_call(es...)
    esc(ChainMap.lazy_call(es...))
end
