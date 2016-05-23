using ChainMap

test_chain = @c begin
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

test_more = @c begin
  (1, 2)
  +(_...)
end

Test.@test test_more == 3

test_function = @l begin
  +(1)
  +(2)
end

Test.@test test_function(1) == 4

test_chain_function = @l -(2, _) +(1)

Test.@test test_chain_function(1) == 2

test_map = @c begin
  1
  x -> x^2 + _
  map([1, 2])
end

Test.@test test_map == [2, 5]

both = @o @c begin
  ~[1,2]
  +(1)
  +(2)
end

Test.@test both == [4, 5]

errror =
  try
    chain(1, :(import ChainMap ))
  catch x
    x
  end

Test.@test errror.msg == "Unsupported expression import ChainMap"

chain_tuple = @c begin
  1
  (2, 3)
end

Test.@test chain_tuple == (1, 2, 3)


readme = @o @c begin
  ~[1, 2]
  -(1)
  ^(2, _)
  begin
    a = _ - 1
    b = _ + 1
    (a, b)
  end
  sum
end

Test.@test readme == [2, 4]

a = ( [1, 2], [3, 4] )
dots_test = @o +( ~(a...) )
Test.@test dots_test == [4, 6]

b = ( [5, 6], [7, 8] )

errrror =
  try
    over( :( +( ~(a...), ~(b...) ) ) )
  catch x
    x
  end

Test.@test errrror.msg == "Cannot map over more than one splatted argument"
