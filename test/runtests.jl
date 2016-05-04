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

test_function = ChainMap.@f begin
  +(1)
  +(2)
end

Test.@test test_function(1) == 4

test_map = ChainMap.@> begin
  1
  x -> x^2 + _
  map([1, 2])
end

Test.@test test_map == [2, 5]

map_test = ChainMap.@.> [1,2] +(1) +(2)
Test.@test map_test == [4, 5]

map_test_block = ChainMap.@.> [1,2] begin
  +(1)
  +(2)
end

Test.@test map_test_block == [4, 5]

function plus(x, y) x + y end

map_all_test = ChainMap.map_all( ([1,2], [2, 4]) , plus )
Test.@test map_all_test == [3, 6]

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
