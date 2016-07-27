using Documenter, ChainMap

makedocs()

deploydocs(
    repo = "github.com/bramtayl/ChainMap.jl.git",
    deps = Deps.pip("pygments", "mkdocs", "mkdocs-material", "python-markdown-math")
)
