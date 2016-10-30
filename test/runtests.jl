using ChainMap
using Base.Test
e = quote
    :b
    sum
    string
    *(~a, " ", _, " ", ~:c)
end

chain_map(e)

a = ["one", "two"]
result = @chain begin
    Dict(:b => [1, 2], :c => ["I", "II"])
    @chain_map begin
        :b
        sum
        string
        *(~a, " ", _, " ", ~:c)
    end
end

@test result == ["one 3 I", "two 3 II"]

@test 1 == @chain_map 1
@test vcat(1) == @link 1 vcat
@test vcat(2, 1) == @link 1 vcat(2, _)
@test ( @chain_line 1 vcat(_, 2) vcat(_, 3) ) ==
    @link ( @link 1 vcat(_, 2) ) vcat(_, 3)
chain_block = @chain begin
    1
    vcat(_, 2)
end

@test chain_block == @chain_line 1 vcat(_, 2)

@test_throws ErrorException ChainMap.chain(:(a + b))
merge_test = @chain begin
    collect_arguments(1, a = 2, b = 3)
    merge(_, collect_arguments(4, a = 5, c = 6) )
end

@test merge_test == collect_arguments(1, 4, a = 5, b = 3, c = 6)
merge_test = @chain begin
    collect_arguments([1, 2])
    unshift(_, vcat)
    LazyCall(_, map)
    merge(_, collect_arguments([3, 4]) )
    run
end

@test merge_test == [[1, 3], [2, 4]]
push_test = @chain begin
    collect_arguments(1, a = 2, b = 3)
    push(_, 4, a = 5, c = 6)
end

@test push_test == collect_arguments(1, 4, a = 5, b = 3, c = 6)
push_test = @chain begin
    collect_arguments([1, 2])
    unshift(_, vcat)
    LazyCall(_, map)
    push(_, [3, 4])
    run
end

@test push_test == [[1, 3], [2, 4]]
unshift_test = @chain begin
    collect_arguments(2, a = 3)
    unshift(_, 1)
end

@test unshift_test == collect_arguments(1, 2, a = 3)
unshift_test = @chain begin
    collect_arguments([1, 2], [3, 4])
    LazyCall(_, map)
    unshift(_, vcat)
    run
end

@test unshift_test == [[1, 3], [2, 4]]
a = collect_arguments(1, 2, a = 3, b = 4)
@test a.positional == (1, 2)
@test a.keyword == Dict{Symbol, Any}(:a => 3, :b => 4)
l = collect_call(vcat, [1, 2], [3, 4])
@test l.function_call == vcat
@test l.arguments == collect_arguments([1, 2], [3, 4])
run_test = @chain begin
    collect_arguments([1, 2], [3, 4])
    unshift(_, vcat)
    collect_arguments(_, map)
    run
end

@test run_test == map(vcat, [1, 2], [3, 4])
run_test = @chain begin
    collect_arguments([1, 2], [3, 4])
    unshift(_, vcat)
    LazyCall(_, map)
    run
end

@test run_test == map(vcat, [1, 2], [3, 4])
run_test = @chain begin
    collect_arguments([1, 2], [3, 4])
    unshift(_, vcat)
    run(_, map)
end

@test run_test == map(vcat, [1, 2], [3, 4])
run_test = @chain begin
    collect_arguments([1, 2], [3,4])
    LazyCall(_, vcat)
    run(_, map)
end

@test run_test == map(vcat, [1, 2], [3, 4])
test_function(arguments...; keyword_arguments...) =
    (arguments, keyword_arguments)

@test ( @lazy_call test_function(1, 2, a = 3) ) ==
    collect_call(test_function, 1, 2, a = 3)
nonstandard(:binary_function, :chain_back)

binary_function(a, b, c) = Expr(:call, b, a, c)
chain_back(a, b, c) = Expr(:call, c, b, a)

@nonstandard binary_function chain_back

@test vcat(1, 2) == @binary_function 1 vcat 2
@test vcat(3, 2) == @chain_back 2 3 vcat

@test "See documentation of [`binary_function`](@ref)" ==
    @chain_line (@doc @binary_function) string chomp

e = :(vcat(~a, ~b) )
f = :map
over(e, f)

a = [1, 2]
b = [3, 4]

@test map((a, b) -> vcat(a, b), a, b) ==
    @over vcat(~a, ~b)
map_tuple(args...; as_tuple = false) =
    if as_tuple
        (map(args...)...)
    else
        map(args...)
    end

e = :( vcat(~a, ~b) )
f = :(map_tuple(as_tuple = true) )

over(e, f)

a = [1, 2]
b = [3, 4]

result = @over ~a + ~b map_tuple(as_tuple = true)

@test map_tuple( (a, b) -> vcat(a, b), a, b, as_tuple = true) ==
    @over vcat(~a, ~b) map_tuple(as_tuple = true)

# `f` must be a call
@test_throws ErrorException over(:(~_ + 1), :(import ChainMap) )
a = 1
_ = Dict(:a => 2)

@test Dict("a" => _[:a] + a, "b" => :b) ==
   @with Dict("a" => :a + a, "b" => ^(:b))
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
A = [1, 2]
B = ( [5, 6], [7, 8] )

unweave_test = @chain begin
    @unweave vcat(~A, ~[3, 4], ~(B...) )
    run(_, map)
end

@test unweave_test ==
      map((a, c, b...) -> vcat(a, c, b...), A, [3, 4], B...)

keyword_test(; keyword_arguments...) = keyword_arguments

a = keyword_test(a = 1, b = 2)

unweave_keyword_test = @chain begin
    @unweave keyword_test(c = 3; ~(a...))
    run
end

@test unweave_keyword_test == keyword_test(c = 3; a... )

# Must include at least one woven argument
@test_throws ErrorException unweave(:(a + b))

# Can splat no more than one positional argument
@test_throws ErrorException unweave(:( ~(a...) + ~(b...) ))

# Can splat no more than one keyword argument
@test_throws ErrorException unweave(:( ~(;a...) + ~(;b...) ))
@test bitnot(1) == ~1
a = ["one", "two"]
result = @chain begin
    Dict(:b => [1, 2], :c => ["I", "II"])
    @chain_map begin
        :b
        sum
        string
        *(~a, " ", _, " ", ~:c)
    end
end

@test result == ["one 3 I", "two 3 II"]
along() = "dummy function; could be a fancy view some day"

Base.run(A::AbstractArray,
         map_call::typeof(map), map_function::Function,
         along_call::LazyCall{typeof(along)},
         reduce_call::typeof(reduce), reduce_function::Function) =
    mapreducedim(map_function, reduce_function, A,
                 along_call.arguments.positional[1] )
fancy = @chain begin
    [1, 2, 3, 4]
    reshape(_, 2, 2)
    collect_arguments(
        _,
        map,
        _ -> -(_, 1),
        @lazy_call( along(1) ),
        reduce,
        +)
    run
end

boring = mapreducedim(x -> x - 1, +, reshape([1, 2, 3, 4], 2, 2), 1)

@test fancy == boring
