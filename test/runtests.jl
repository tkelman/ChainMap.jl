workspace()

using ChainMap

function run_doctests(filein)
  text = readlines(filein)

  starts = map(_ -> ismatch(r"```.+", chomp(_) ), text)
  ends = map(_ -> chomp(_) == "```", text)
  Test.@test sum(starts) == sum(ends)

  withbounds = text[cumsum(starts) - cumsum(ends) .== 1]
  withoutbounds = filter(x -> !startswith(x, "```"), withbounds)
  backslash_removed = map(x -> replace(x, r"\\", ""), withoutbounds)

  tempfile = joinpath(tempdir(), "__tmp.jl")
  write(tempfile, backslash_removed)
  include(tempfile)
end

run_doctests(joinpath(Pkg.dir("ChainMasrc", "doc.jl"))
run_doctests(joinpath(Pkg.dir("ChainMap"), "docs", "src", "index.md"))
