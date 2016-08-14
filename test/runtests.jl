using ChainMap
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
@test a.keyword == Dict{Symbol, Any}(:a => 3, :b => 4)
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
@test ( @lazy_call +(1, 2) ) == collect_call(+, 1, 2)

@test ( @lazy_call(1) ) == 1
@test ( @chain 1 vcat(2) ) ==
      vcat(1, 2)

@test ( @chain 1 vcat(2, _) ) ==
      vcat(2, 1)

@test ( @chain (2, 1) vcat(3, _...) ) ==
      vcat(3, 2, 1)

@test ( @chain 1 begin -(3, 2 + _) end ) == 0
@test (@chain 1 vcat) == vcat(1)
chain_block = @chain begin
    1
    vcat(2)
end

@test chain_block == @chain 1 vcat(2)

# Cannot chain only one argument
@test_throws ErrorException ChainMap.chain(:(1 + 1))
@test ( @chain 1 vcat(2) vcat(3) ) ==
      ( @chain ( @chain 1 vcat(2) ) vcat(3) )
a = [1, 2]
b = ( [5, 6], [7, 8] )

fancy = @chain begin
    a
    begin @unweave vcat(~_, ~_, ~[3, 4], ~(b...) ) end
    run(map)
end

boring = map((a, c, b...) -> vcat(a, a, c, b...), a, [3, 4], b...)

@test fancy == boring

# No arguments marked with tildas detected
@test_throws ErrorException ChainMap.unweave(:( 1 + 1 ))
# Cannot include more than one splatted argument
@test_throws ErrorException ChainMap.unweave(:( ~(a...) + ~(b...) ))
@test bitnot(1) == ~1
binaryfun(a, b, c) = :($b($a, $c))
chainback(a, b, c) = :($c($b, $a))

@nonstandard binaryfun chainback

@test (@binaryfun 1 vcat 2) == vcat(1, 2)
@test (@chainback 2 3 vcat) == vcat(3, 2)

@test (@chain (@doc @binaryfun) string chomp) ==
      "See documentation of [`binaryfun`](@ref)"
push_test = @chain begin
    1
    collect_arguments
    @push_block begin
        2
        a = 3
    end
end

@test push_test == push(collect_arguments(1), 2, a = 3)
arguments_test = @chain begin
    1
    @arguments_block begin
        2
        a = 3
    end
end

@test arguments_test == collect_arguments(1, 2, a = 3)
A = [1, 2]
B = ( [5, 6], [7, 8] )

fancy = @chain begin
    A
    begin @unweave vcat(~_, ~_, ~[3, 4], ~(B...) ) end
    run(map)
end

boring = map((a, c, b...) -> vcat(a, a, c, b...), A, [3, 4], B...)
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
        x -> x + 1
        @lazy_call along(1)
        reduce
        +
    end
    run
end

boring = mapreducedim(x -> x + 1, +, reshape([1, 2, 3, 4], 2, 2), 1)

@test fancy == boring
