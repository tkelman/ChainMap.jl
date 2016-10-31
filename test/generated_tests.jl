using ChainMap
using Base.Test
@test vcat(1) == ChainMap.@link 1 vcat
@test vcat(2, 1) == ChainMap.@link 1 vcat(2, _)
e = quote
    1
    vcat(_, 2)
end

ChainMap.chain_block(e)

a_block = ChainMap.@chain_block begin
    1
    vcat(_, 2)
end

@test a_block == vcat(1, 2)

# Can only chain begin blocks
@test_throws ErrorException ChainMap.chain_block(:(a + b))

# Cannot chain assignments, functions, or =>
@test_throws ErrorException ChainMap.chain_block(quote
    a = 1
    2
end)
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
nonstandard(:binary_function, :chain_back)

binary_function(a, b, c) = Expr(:call, b, a, c)
chain_back(a, b, c) = Expr(:call, c, b, a)

@nonstandard binary_function chain_back

@test vcat(1, 2) == @binary_function 1 vcat 2
@test vcat(3, 2) == @chain_back 2 3 vcat

new_doc_string = @chain begin
    (@doc @binary_function)
    string
    chomp
end

@test new_doc_string == "See documentation of [`binary_function`](@ref)"
e = Expr(:parameters, Expr(:..., :a) )
first = :parameters
second = :...

@test ChainMap.double_match(e, first, second)
@test !ChainMap.double_match(:b, :parameters, :...)
e = Expr(:parameters, Expr(:..., :a) )
@test ChainMap.replace_key(e, :b) == Expr(:parameters, Expr(:..., :b) )

e = Expr(:..., :a)
@test ChainMap.replace_key(e, :b) == Expr(:..., :b)

@test ChainMap.replace_key(:a, :b) == :b
a = Expr(:..., :a)

@test ChainMap.unparameterize(Expr(:parameters, a) ) == a

@test ChainMap.unparameterize(:b) == :b
e = :a
symbol = :z
d = Dict(:a => :b, :(a + 1) => :(b + 1))

ChainMap.add_key!(d, e, symbol)
@test d[:a] == :b

ChainMap.add_key!(d, :c, symbol)
@test d[:c] == :z

e = Expr(:parameters, Expr(:..., :d) )
@test ChainMap.add_key!(d, e, symbol) == Expr(:..., :z)
@test d[e] == Expr(:parameters, Expr(:..., :z) )
d = Dict()
e = :( 1 + ~(a))
ChainMap.replace_record!(e, d)
@test :a in keys(d)
f = x -> x == :a
@test ChainMap.negate(f)(:b)
e = :(~_ + 1)
ChainMap.split_anonymous(e)
e = :( vcat(~a, ~b) )
f = :broadcast
over(e, f)

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

e = :( vcat(~a, ~b) )
f = :(broadcast_tuple(as_tuple = true) )
over(e, f)

a = [1, 2]
b = [3, 4]

@test broadcast_tuple( (a, b) -> vcat(a, b), a, b, as_tuple = true) ==
@over vcat(~a, ~b) broadcast_tuple(as_tuple = true)

# `f` must be a call
@test_throws ErrorException over(:(~_ + 1), :(import ChainMap) )
file_in = joinpath(Pkg.dir(), "ChainMap", "src", "chain.jl")

ChainMap.code_lines(file_in)
make_tests("ChainMap")
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
