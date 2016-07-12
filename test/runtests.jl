using ChainMap

Test.@test (@o 1) == 1

Test.@test bitnot(1) == -2

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

_ = 1

test_ = @c begin
  _
  +(_, 1)
  +(2)
end

Test.@test test_ == 4

test_function = @l @c begin
  +(_, 1)
  +(2)
end

Test.@test test_function(1) == 4

test_chain_function = @l @c -(2, _) +(1)

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

chain_tuple = @c begin
  1
  (2, 3)
end

Test.@test chain_tuple == (1, 2, 3)

readme = @l @o @c begin
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
dots_test = @o +( ~(a...) )
Test.@test dots_test == [4, 6]

b = ( [5, 6], [7, 8] )

errrror =
  try
    over!( :( +( ~(a...), ~(b...) ) ) )
  catch x
    x
  end

Test.@test errrror.msg == "Cannot map over more than one splatted argument"

test = Arguments()
Test.@test test == Arguments((), Any[])

@safe push! unshift!

test1 = Arguments(1, 2, a = 3, b = 4)
test2 = push(test1, 5, 6; c = 7, d = 8 )
Test.@test test2 ==
  Arguments((1,2,5,6),
                     Any[(:a,3),(:b,4),(:c,7),(:d,8)])

function test_function_2(a, b, c; d = 4)
  a - b + c - d
end

test_arguments = @c begin
  1
  Arguments()
  push(2, d = 2)
  unshift(3)
  run(test_function_2)
end

Test.@test test_arguments == test_function_2(3, 1, 2; d = 2)

a = [1, 2]
b = @c a push(1) unshift(2)
Test.@test a != b

errror =
  try
    safe(:hello)
  catch x
    x
  end

Test.@test errror.msg == "Function must end in !"

a = [1, 2]
b = [3, 4]

function multi_push!(a; b = [1, 2])
  push!(a, 1)
  push!(b, 2)
  (a, b)
end

@safe multi_push!
(a_fix, b_fix) = multi_push(a; b = b)
Test.@test a_fix != a
Test.@test b_fix != b
