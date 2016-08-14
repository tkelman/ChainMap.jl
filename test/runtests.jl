using ChainMap
using Base.Test

arguments_test = @chain begin
    collect_arguments(1, a = 3)
    push(2, b = 4)
end

@test arguments_test ==
      collect_arguments(1, 2, a = 3, b = 4)
@test (@chain begin
                  collect_arguments(2, a = 3)
                  unshift(1)
              end) ==
            collect_arguments(1, 2, a = 3)
a = collect_arguments(1, 2, a = 3, b = 4)
@test a.positional == (1, 2)
@test a.keyword == Dict{Symbol, Any}(:a => 3, :b => 4)
@test (@chain begin
                  collect_call(vcat, [1, 2], [3, 4])
                  run(map)
              end) ==
      map(vcat, [1, 2], [3, 4])
Test.@test (@chain begin
                 collect_call(vcat, [1, 2], [3, 4])
                 collect_arguments(map)
                 run
             end) ==
      map(vcat, [1, 2], [3, 4])
test_function(a, b; c = 4) = a - b + c

@test (@chain begin
                  collect_arguments(1, 2, c = 3)
                  LazyCall(test_function)
                  run
              end) ==
      test_function(1, 2, c = 3)
test_function(a, b; c = 4) = a - b + c

@test (@chain begin
                  collect_arguments(1, 2, c = 3)
                  run(test_function)
              end) ==
      test_function(1, 2, c = 3)
@test (@chain begin
                  collect_arguments([1, 2], [3,4])
                  LazyCall(vcat)
                  run(map)
              end) ==
      map(vcat, [1, 2], [3, 4])
@test ( @lazy_call +(1, 2) ) ==
      collect_call(+, 1, 2)

@test ( @lazy_call(1) ) == 1
@test ( @chain 1 vcat(2) ) ==
      vcat(1, 2)

@test ( @chain 1 vcat(2, _) ) ==
      vcat(2, 1)

@test ( @chain (2, 1) vcat(3, _...) ) ==
      vcat(3, 2, 1)

@test ( @chain 1 begin -(3, 2 + _) end ) == 0
@test (@chain 1 vcat) == vcat(1)
@test (@chain begin
                  1
                  vcat(2)
               end) ==
      @chain 1 vcat(2)

@test (@chain 1 + 1) == 2
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
@test bitnot(1) == ~1
binaryfun(a, b, c) = :($b($a, $c))
chainback(a, b, c) = :($c($b, $a))
@nonstandard binaryfun chainback
@test (@binaryfun 1 vcat 2) == vcat(1, 2)
@test (@chainback 2 3 vcat) == vcat(3, 2)
@test (@chain begin
           collect_arguments(1)
           @push_block begin
               2
               a = 3 end end) ==
      push(collect_arguments(1), 2, a = 3)
@test (@chain begin
           1
           @arguments_block begin
               2
               a = 3 end end) ==
      collect_arguments(1, 2, a = 3)
A = [1, 2]
B = [3, 4]

fancy = @chain begin
    A
    map(x -> x + 1, _)
    begin @unweave vcat(~_, ~B, ~[5, 6] ) end
    run(map)
end

boring = map((a, b, c) -> vcat(a, b, c), map(x -> x + 1, A), B, [5, 6])

@test fancy == boring
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
