using ChainMap
import DataStructures
using Base.Test

merge_test = @chain begin
    collect_arguments(1, a = 2, b = 3)
    merge(collect_arguments(4, a = 5, c = 6) )
end

@test merge_test == collect_arguments(1, 4, a = 5, b = 3, c = 6)
push_test = @chain begin
    collect_arguments(1, a = 2, b = 3)
    push(4, a = 5, c = 6)
end

@test push_test == collect_arguments(1, 4, a = 5, b = 3, c = 6)
unshift_test = @chain begin
    collect_arguments(2, a = 3)
    unshift(1)
end

@test unshift_test == collect_arguments(1, 2, a = 3)
a = collect_arguments(1, 2, a = 3, b = 4)
@test a.positional == (1, 2)
@test a.keyword == DataStructures.OrderedDict{Symbol, Any}(:a => 3, :b => 4)
l = collect_call(vcat, [1, 2], [3, 4])
@test l.function_call == vcat
@test l.arguments == collect_arguments([1, 2], [3, 4])
run_test = @chain begin
    collect_arguments([1, 2], [3, 4])
    unshift(vcat)
    collect_arguments(map)
    run
end

@test run_test == map(vcat, [1, 2], [3, 4])
run_test = @chain begin
    collect_arguments([1, 2], [3, 4])
    unshift(vcat)
    LazyCall(map)
    run
end

@test run_test == map(vcat, [1, 2], [3, 4])
run_test = @chain begin
    collect_arguments([1, 2], [3, 4])
    unshift(vcat)
    run(map)
end

@test run_test == map(vcat, [1, 2], [3, 4])
run_test = @chain begin
    collect_arguments([1, 2], [3,4])
    LazyCall(vcat)
    run(map)
end

@test run_test == map(vcat, [1, 2], [3, 4])
test_function(arguments...; keyword_arguments...) =
    (arguments, keyword_arguments)

@test ( @lazy_call test_function(1, 2, a= 3) ) ==
    collect_call(test_function, 1, 2, a = 3)
push_test = @chain begin
    1
    collect_arguments
    @push_block begin
        2
        a = 3
    end
end

@test push_test == @chain 1 collect_arguments push(2, a = 3)
arguments_test = @chain begin
    1
    @arguments_block begin
        2
        a = 3
    end
end

@test arguments_test == collect_arguments(1, 2, a = 3)
@test vcat(1, 2) == @chain 1 vcat(2)

@test vcat(2, 1) == @chain 1 vcat(2, _)

@test vcat(3, 2, 1) == @chain (2, 1) vcat(3, _...)

@test 0 == @chain 1 begin -(3, 2 + _) end

keyword_test(; keyword_arguments...) = keyword_arguments

@test keyword_test(a = 1) == @chain 1 keyword_test(a = _)

@test keyword_test(b = 2, a = 1) ==
    @chain keyword_test(a = 1) keyword_test(b = 2; _...)

@test vcat(1) == @chain 1 vcat
@test 1 == @chain 1

chain_block = @chain begin
    1
    vcat(2)
end

@test chain_block == @chain 1 vcat(2)
@test ( @chain 1 vcat(2) vcat(3) ) ==
    @chain ( @chain 1 vcat(2) ) vcat(3)
lambda_function = @lambda vcat(2) vcat(3)
@test lambda_function(1) == vcat(1, 2, 3)

lambda_function_2 = @lambda -(_, 1)
@test lambda_function_2(2) == 1
A = [1, 2]
B = ( [5, 6], [7, 8] )

unweave_test = @chain begin
    @unweave vcat(~A, ~[3, 4], ~(B...) )
    run(map)
end

@test unweave_test ==
      map((a, c, b...) -> vcat(a, c, b...), A, [3, 4], B...)

keyword_test(; keyword_arguments...) = keyword_arguments

a = keyword_test(a = 1, b = 2)

unweave_keyword_test = @chain begin
    @unweave keyword_test(; c = 3, ~(; a...))
    run
end

@test unweave_keyword_test == keyword_test(c = 3; a... )

# No arguments marked with tildas detected
@test_throws ErrorException ChainMap.unweave(:( 1 + 1 ))
# Cannot include more than one splatted argument
@test_throws ErrorException ChainMap.unweave(:( ~(a...) + ~(b...) ))
A = [1, 2]
B = ( [5, 6], [7, 8] )

unweave_test = @chain begin
    A
    @unweave vcat(~[3, 4], ~(B...) )
    run(map)
end

@test unweave_test ==
      map((a, c, b...) -> vcat(a, c, b...), A, [3, 4], B...)
@test bitnot(1) == ~1
binaryfun(a, b, c) = :($b($a, $c))
chainback(a, b, c) = :($c($b, $a))

@nonstandard binaryfun chainback

@test vcat(1, 2) == @binaryfun 1 vcat 2
@test vcat(3, 2) == @chainback 2 3 vcat

"See documentation of [`binaryfun`](@ref)" ==
    @chain (@doc @binaryfun) string chomp

A = [1, 2]
B = ( [5, 6], [7, 8] )

unweave_test = @chain begin
    A
    @unweave vcat(~[3, 4], ~(B...) )
    run(map)
end

@test unweave_test ==
      map((a, c, b...) -> vcat(a, c, b...), A, [3, 4], B...)
along() = "dummy function; could be a fancy view some day"

Base.run(A::AbstractArray,
         map_call::typeof(map), map_function::Function,
         along_call::LazyCall{typeof(along)},
         reduce_call::typeof(reduce), reduce_function::Function) =
    mapreducedim(map_function, reduce_function, A,
                 along_call.arguments.positional[1] )

fancy = @chain begin
    [1, 2, 3, 4]
    reshape(2, 2)
    @arguments_block begin
        map
        @lambda *(2) -(1)
        @lazy_call along(1)
        reduce
        +
    end
    run
end

boring = mapreducedim(x -> 2*x - 1, +, reshape([1, 2, 3, 4], 2, 2), 1)

@test fancy == boring
