using ChainMap

"""
    code_lines(file_in)

A function which extracts just the lines containing code from markdown.

```julia
file_in = joinpath("/home", "brandon",
                   ".julia", "v0.5", "ChainMap",
                   "src", "chain.jl")

code_lines(file_in)
```
"""
function code_lines(file_in)
  text = readlines(file_in)

  starts = @chain begin
      text
      @map @chain begin
          chomp(_)
          ismatch(r"^```.+", _)
      end
  end

  ends = @chain begin
      text
      @map @chain begin
          chomp(_)
          _ == "```"
      end
   end

  Test.@test sum(starts) == sum(ends)

  @chain begin
      cumsum(starts) - cumsum(ends) .== 1
      text[_]
      @lambda filter !startswith(_, "```")
      @map replace(_, r"\\", "")
  end

end

"""
    make_tests(path, head = "")

Populates your runtest.jl file with all of the julia code in your docstrings.

An optional header string, or vector of header strings, `head`, can be added.
`path` is the path to your package.

# Examples
```julia
path_in = "C:\\Users\\jsnot\\.julia\\v0.4\\ChainMap"
head = ["using ChainMap", "import DataStructures",
        "import DataFrames", "using Base.Test"]
make_tests(path_in, head)
```
"""
function make_tests(package)

    path_in = joinpath(Pkg.dir(), package)
    head_cat = *("using ", package, "\nusing Base.Test\n")

    @chain begin
        path_in
        joinpath(_, "src")
        readdir
        @map joinpath(path_in, "src", _)
        [_; joinpath(path_in, "README.md") ]
        map(code_lines, _)
        vcat(head_cat, _...)
        write(joinpath(path_in, "test", "runtests.jl"), _)
    end
end

make_tests("ChainMap")
