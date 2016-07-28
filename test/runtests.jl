using ChainMap

push1!(a) = push!(a, 1)
push2!(a) = push!(a, 2)

@safe push1! push2!
a = [0]
b = [0, 1, 2]
c = @chain a push1 push2
Test.@test a != b == c
plus(a, b) = a + b
minus(a, b) = a - b
plusone(a) = a + 1

Test.@test (@chain begin
                     1
                     plus(1)
                   end) ==
           @chain 1 plus(1)

Test.@test (@chain 1 plusone) == plusone(1)

Test.@test (@chain 1 minus(2, _) ) ==
           minus(2, 1)

Test.@test (@chain 1 plus(2) ) ==
           plus(1, 2)

Test.@test (@chain begin
                     1
                     begin
                       b = 2
                       minus(b, _)
                     end
                   end) ==
           begin
             b = 2
             minus(b, 1)
           end

Test.@test (@chain 1 minus(2) plus(3) ) ==
           plus(minus(1, 2), 3)
testlambda = @lambda -(2, _)
Test.@test  testlambda(1) == -(2, 1)
Test.@test (@over 1) == 1
Test.@test (@over 1 + 2) == 3

Test.@test (@over +( ~[1, 2], ~[3, 4] ) ) ==
           [1 + 3, 2 + 4]

a = [1, 2]
b = [3, 4]
c = ( [5, 6], [7, 8] )
d = 9

Test.@test (@over ~a + ~a + ~b) ==
           [1 + 1 + 3, 2 + 2 + 4]

Test.@test (@over +(~a, ~d) ) ==
           [1 + 9, 2 + 9]

Test.@test (@over ~a + ~(c...) ) ==
           [ 1 + 5 + 7, 2 + 6 + 8 ]

Test.@test (@over begin
                    e = ~a
                    e + 1
                  end ) ==
            [2, 3]
Test.@test bitnot(1) == ~1
a = Arguments(1, 2, a = 3, b = 4)
Test.@test a.positional ==
           (1, 2)
Test.@test a.keyword ==
           Dict{Symbol, Any}(:a => 3, :b => 4)
Test.@test (@chain Arguments(1, a = 3) push(2, b = 4) ) ==
           Arguments(1, 2, a = 3, b = 4)
Test.@test (@chain Arguments(1, a = 3) unshift(2) ) ==
           Arguments(2, 1, a = 3)
testfunction(a, b; c = 4) = a - b + c

Test.@test (@chain Arguments(1, 2, c = 3) run(testfunction) ) ==
           testfunction(1, 2, c = 3)
plus(a, b) = +(a, b)
minus(a, b) = -(a, b)

binaryfun(a, b, c) = :($b($a, $c))
chainback(a, b, c) = :($c($b, $a))

@nonstandard binaryfun chainback

Test.@test (@binaryfun 1 plus 2) == 3
Test.@test (@chainback 2 3 minus) == 1
line_to_block1(f) = f
double_line_to_block1(f) = :($f; $f)

@multiblock line_to_block1 double_line_to_block1
@nonstandard line_to_block double_line_to_block

Test.@test (@line_to_block a = 2 a - 1) == 1
@double_line_to_block a = a + 1 a = a/2
Test.@test a == 1
@make_aliases
plus(a, b) = a + b
Test.@test (@c 1 plus(2) ) == (@chain 1 plus(2) )
readme = @lambda @over @chain begin
  ~_
  -(1)
  ^(2, _)
  begin
    a = _ - 1
    b = _ + 1
    (a, b)
  end
  sum
end

Test.@test readme([1, 2]) == [2, 4]
function test_function(a, b, c; d = 4)
  a - b + c - d
end

test_arguments = @chain begin
  1
  Arguments
  push(2, d = 2)
  unshift(3)
  run(test_function)
end

Test.@test test_arguments == test_function(3, 1, 2; d = 2)
Modules = [ChainMap]
