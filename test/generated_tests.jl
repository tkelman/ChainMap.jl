using ChainMap
using Base.Test
head = 1
tail = :vcat
head = 1
tail = :( vcat(2, _) )
e = quote
    1
    vcat(_, 2)
end
e = quote
    begin
        1
        vcat(2, _)
    end
    vcat(_, begin
        2
        vcat(3, _)
    end)
    vcat(3, _)
end
@chain begin
    test = begin
        begin
            1
            vcat(2, _)
        end
        vcat(_, begin
            2
            vcat(3, _)
        end)
        vcat(3, _)
    end

    @test test == vcat(3, vcat(vcat(2, 1), vcat(3, 2) ) )
end
e = Expr(:parameters, Expr(:..., :a) )
first = :parameters
second = :...
e = Expr(:parameters, Expr(:..., :a) )
@test ChainMap.replace_key(e, :b) == Expr(:parameters, Expr(:..., :b) )

e = Expr(:..., :a)
@test ChainMap.replace_key(e, :b) == Expr(:..., :b)

@test ChainMap.replace_key(:a, :b) == :b
e = Expr(:parameters, a)
e = :b
e = :a
symbol = :z
d = Dict(:a => :b, :(a + 1) => :(b + 1))

e = Expr(:parameters, Expr(:..., :d) )
d = Dict()
e = :( 1 + ~(a))
f = x -> x == :a
e = :(~_ + 1)
e = :( vcat(~a, ~b) )
f = :broadcast
e = :( vcat(~a, ~b) )
f = :(broadcast_tuple(as_tuple = true) )
a = [1, 2]
b = [3, 4]

@test broadcast( (a, b) -> vcat(a, b), a, b) ==
    @over vcat(~a, ~b)

broadcast_tuple(args...; as_tuple = false) =
    if as_tuple
        (broadcast(args...)...)
    else
        broadcast(args...)
    end

a = [1, 2]
b = [3, 4]

@test broadcast_tuple( (a, b) -> vcat(a, b), a, b, as_tuple = true) ==
    @over vcat(~a, ~b) broadcast_tuple(as_tuple = true)

# `f` must be a call
@test_throws ErrorException ChainMap.over(:(~_ + 1), :(import ChainMap) )
file_in = joinpath(Pkg.dir(), "ChainMap", "src", "chain.jl")

ChainMap.code_lines(file_in)
ChainMap.make_tests("ChainMap")
a = 1
_ = Dict(:a => 2)

@test Dict("a" => _[:a] + a, "b" => :b) ==
   @with Dict("a" => :a + a, "b" => ^(:b))
@chain begin
    a = ["one", "two"]

    result = begin
        Dict(:b => [1, 2], :c => ["I", "II"])
        @with @over begin
            :b
            sum
            string
            *(~a, " ", _, " ", ~:c)
        end
    end

    @test result == ["one 3 I", "two 3 II"]
end
