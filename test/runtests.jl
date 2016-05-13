import ChainMap

test_chain = ChainMap.@> begin
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

test_more = ChainMap.@> begin
  (1, 2)
  +(_...)
end

Test.@test test_more == 3

test_function = ChainMap.@f begin
  +(1)
  +(2)
end

Test.@test test_function(1) == 4

test_function_multi = ChainMap.@fs begin
  +(_...)
end

Test.@test test_function_multi(1, 2) == 3

test_map = ChainMap.@> begin
  1
  x -> x^2 + _
  map([1, 2])
end

map_test = ChainMap.@.>> ([1, 2], [3, 4]) +(_...)
Test.@test map_test == [4, 6]

map_test_block = ChainMap.@.> [1,2] begin
  +(1)
  +(2)
end

Test.@test map_test_block == [4, 5]


errror =
  try
    ChainMap.chain(1, :(import ChainMap ))
  catch x
    x
  end

Test.@test errror.msg == "Unsupported expression import ChainMap"

chain_tuple = ChainMap.@> begin
  1
  (2, 3)
end

Test.@test chain_tuple == (1, 2, 3)


readme = ChainMap.@> begin
  [1, 2]
  (_, _)
  ChainMap.@.>> begin
    +(_...)
    -(1)
    ^(2, _)
  end
  begin
    a = _ - 1
    b = _ + 1
    [a, b]
  end
  sum
end

Test.@test readme == 20
