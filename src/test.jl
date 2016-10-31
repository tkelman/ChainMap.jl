export make_tests

"""
    code_lines(file_in)

A function which extracts just the lines containing code from markdown.

```julia
file_in = joinpath(Pkg.dir(), "ChainMap", "src", "chain.jl")

ChainMap.code_lines(file_in)
```
"""
code_lines(file_in) = @chain begin

    text = readlines(file_in)

    starts = @over begin
        chomp(~text)
        ismatch(r"^```.+", _)
    end

    ends = @over begin
        chomp(~text)
        _ == "```"
    end

    Test.@test sum(starts) == sum(ends)

    begin
        @over ~cumsum(starts) - ~cumsum(ends) == 1
        text[_]
        @over !startswith(~_, "```") filter
        @over replace(~_, r"\\", "")
    end
end

export make_tests
"""
    make_tests(package::AbstractString)

Populates your runtest.jl file with all of the julia code in your docstrings.

`package` is the quoted name of a folder in your package directory

# Examples
```julia
make_tests("ChainMap")
```
"""
make_tests(package) = @chain begin

    path_in = joinpath(Pkg.dir(), package)
    head_cat = *("using ", package, "\nusing Base.Test\n")

    begin
        path_in
        joinpath(_, "src")
        readdir
        @over joinpath(path_in, "src", ~_)
        [_; joinpath(path_in, "README.md") ]
        map(code_lines, _)
        vcat(head_cat, _...)
        write(joinpath(path_in, "test", "generated_tests.jl"), _)
    end

end
