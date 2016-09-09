using ChainMap
import DataStructures
import NullableArrays
import DataFrames
using Base.Test
na =  NullableArrays.NullableArray
a = na(["one", "two"], [false, true])
result = @chain begin
    Dict(:b => na([1, 2]), :c => na(["I", "II"]))
    @chain_map begin
        :b
        sum
        get
        string
        *(~a, " ", _, " ", ~:c)
    end
end

@test get(result[1]) == "one 3 I"
@test result.isnull == [false, true]
@test vcat(1) == @chain 1 vcat
@test vcat(2, 1) == @chain 1 vcat(2, _)
@test ( @chain 1 vcat(_, 2) vcat(_, 3) ) ==
    @chain ( @chain 1 vcat(_, 2) ) vcat(_, 3)
@test 1 == @chain 1

chain_block = @chain begin
    1
    vcat(_, 2)
end

@test chain_block == @chain 1 vcat(_, 2)
lambda_function = @lambda vcat(_, 2)
@test lambda_function(1) == vcat(1, 2)
f = :map
e = :(vcat(_, 1))
lambda(f, e)

_ = [1, 2]
@test [[1, 1], [2, 1]] == @lambda map vcat(_, 1)
e = :(_ + 1)
f = :(NullableArrays.map(lift = true))

lambda(f, e)

_ = NullableArrays.NullableArray([1, 2], [false, true])

result = @lambda NullableArrays.broadcast(lift = true) _ + 1

@test result.values[1] == 2
@test result.isnull == [false, true]

# `f` must be a call
@test_throws ErrorException lambda(:(import ChainMap), :(_ + 1) )
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

@test ( @lazy_call test_function(1, 2, a= 3) ) ==
    collect_call(test_function, 1, 2, a = 3)
binaryfun(a, b, c) = Expr(:call, b, a, c)
chainback(a, b, c) = Expr(:call, c, b, a)

@nonstandard binaryfun chainback

@test vcat(1, 2) == @binaryfun 1 vcat 2
@test vcat(3, 2) == @chainback 2 3 vcat

@test "See documentation of [`binaryfun`](@ref)" ==
    @chain (@doc @binaryfun) string chomp

a = 1
_ = DataFrames.DataFrame(a = 2)

@test DataFrames.DataFrame(b = _[:a] + a, c = :d) ==
   @with DataFrames.DataFrame(b = :a + a, c = ^(:d))
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
@test 1 == @unweave 1
@test 1 == @unweave +(1)

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

# Can splat no more than one positional argument
@test_throws ErrorException unweave(:( ~(a...) + ~(b...) ))

# Can splat no more than one keyword argument
@test_throws ErrorException unweave(:( ~(;a...) + ~(;b...) ))
@test 1 == @unweave 1 1
@test 1 == @unweave 1 +(1)

e = :(vcat(~a, ~b) )
f = :broadcast
unweave(f, e)

a = [1, 2]
b = [3, 4]

@test broadcast((a, b) -> vcat(a, b), a, b) ==
    @unweave broadcast vcat(~a, ~b)
@test 1 == @unweave +(1) 1
@test 1 == @unweave +(1) +(1)

e = :(~a + ~b)
f = :(NullableArrays.broadcast(lift = true))

unweave(f, e)

a = NullableArrays.NullableArray([1, 2])
b = NullableArrays.NullableArray([3, 4], [false, true])

result = @unweave broadcast(lift = true) ~a + ~b

@test result.values[1] == 4
@test result.isnull == [false, true]

# `f` must be a call
@test_throws ErrorException unweave(:(import ChainMap), :(~_ + 1) )
@test bitnot(1) == ~1
na = NullableArrays.NullableArray
a = na(["one", "two"], [false, true])
result = @chain begin
    Dict(:b => na([1, 2]), :c => na(["I", "II"]))
    @chain_map begin
        :b
        sum
        get
        string
        *(~a, " ", _, " ", ~:c)
    end
end

@test get(result[1]) == "one 3 I"
@test result.isnull == [false, true]
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
    run(_)
end

boring = mapreducedim(x -> x - 1, +, reshape([1, 2, 3, 4], 2, 2), 1)

@test fancy == boring
