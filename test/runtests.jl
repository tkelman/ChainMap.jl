workspace()
import ChainMap

Test.@test (ChainMap.@o 1) == 1

Test.@test ChainMap.bitnot(1) == -2


test_chain = ChainMap.@c begin
  1
  +(1)
  +(_, 1)
  begin
    a = 1 + _
    a
  end
  sum
end

Test.@test test_chain == 4

test_more = ChainMap.@c begin
  (1, 2)
  +(_...)
end

Test.@test test_more == 3

_ = 1

test_ = ChainMap.@c begin
  _
  +(_, 1)
  +(2)
end

Test.@test test_ == 4

test_function = ChainMap.@l ChainMap.@c begin
  +(_, 1)
  +(2)
end

Test.@test test_function(1) == 4

test_chain_function = ChainMap.@l ChainMap.@c -(2, _) +(1)

Test.@test test_chain_function(1) == 2

test_map = ChainMap.@c begin
  1
  x -> x^2 + _
  map([1, 2])
end

Test.@test test_map == [2, 5]

both = ChainMap.@o ChainMap.@c begin
  ~[1,2]
  +(1)
  +(2)
end

Test.@test both == [4, 5]

chain_tuple = ChainMap.@c begin
  1
  (2, 3)
end

Test.@test chain_tuple == (1, 2, 3)


readme = ChainMap.@l ChainMap.@o ChainMap.@c begin
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

a = ( [1, 2], [3, 4] )
dots_test = ChainMap.@o +( ~(a...) )
Test.@test dots_test == [4, 6]

b = ( [5, 6], [7, 8] )

errrror =
  try
    ChainMap.over( :( +( ~(a...), ~(b...) ) ) )
  catch x
    x
  end

Test.@test errrror.msg == "Cannot map over more than one splatted argument"

test = ChainMap.Arguments()
Test.@test test == ChainMap.Arguments((), Any[])

test1 = ChainMap.Arguments(1, 2, a = 3, b = 4)
test2 = ChainMap.push(test1, 5, 6, c = 5, d = 6)
Test.@test test2 == ChainMap.Arguments((1,2,5,6),Any[(:a,3),(:b,4),(:c,5),(:d,6)])

function test_function_2(a, b, c; d = 4)
  a - b + c - d
end

test_arguments = ChainMap.@c begin
  1
  ChainMap.Arguments()
  ChainMap.push(2, d = 2)
  ChainMap.unshift(3)
  ChainMap.run(test_function_2)
end

Test.@test test_arguments == test_function_2(3, 1, 2; d = 2)
