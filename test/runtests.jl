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
test_function(a, b) = vcat(a, b)

@test (@chain begin
                  collect_call(test_function, [1, 2], [3])
                  run(broadcast)
              end) ==
      [ [1, 3], [2, 3] ]
Test.@test (@chain begin
                 collect_call(+, [1, 2], [3, 4])
                 collect_arguments(map)
                 run
             end) ==
      [4, 6]
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
test_function(a, b) = vcat(a, b)

@test (@chain begin
                  collect_arguments([1, 2], [3])
                  LazyCall(test_function)
                  run(broadcast)
              end) ==
      [ [1, 3], [2, 3] ]
@test ( @lazy_call +(1, 2) ) ==
      collect_call(+, 1, 2)

@test ( @lazy_call(1) ) == 1
@test ( @chain 1 vcat(2) ) ==
      vcat(1, 2)

@test ( @chain 1 vcat(2, _) ) ==
      vcat(2, 1)

@test ( @chain (2, 1) vcat(3, _...) ) ==
      vcat(3, 2, 1)

@test ( @chain 1 begin vcat(2) end ) ==
      vcat(2)
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

@test (@chain begin
                  @unweave vcat(~a, ~a, ~[3, 4], ~(b...) )
                  run(map)
              end) ==
      [ [1, 1, 3, 5, 7], [2, 2, 4, 6, 8] ]
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
ChainMap.run(l::LazyCall,
             map_call::typeof(map),
             slice_call::LazyCall{typeof(slice)}) =
    mapslices(l.function_call, l.arguments.positional[1],
              slice_call.arguments.positional[1] )

Base.run(l::LazyCall,
         map_call::typeof(map),
         slice_call::LazyCall{typeof(slice)},
         reduce_call::LazyCall{typeof(reduce)}) =
    mapreducedim(l.function_call, reduce_call.arguments.positional[1],
                 l.arguments.positional[1], slice_call.arguments.positional[1] )
fancy = @chain begin
    [1, 2, 3, 4]
    reshape(2, 2)
    begin @unweave (~_ + 1)/~_ end
    @arguments_block begin
        map
        @lazy_call slice(1)
        @lazy_call reduce(+)
    end
    run
end

boring = mapreducedim(x -> (x + 1)/x, +, reshape([1, 2, 3, 4], 2, 2), 1)

@test fancy == boring
