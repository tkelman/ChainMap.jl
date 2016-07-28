using ChainMap

function run_doctests(filein)
  text = readlines(filein)
  starts = map(_ -> ismatch(r"```.+", chomp(_) ), text)
  ends = map(_ -> chomp(_) == "```", text)
  Test.@test sum(starts) == sum(ends)

  withbounds = text[cumsum(starts) - cumsum(ends) .== 1]
  withoutbounds = filter(x -> !startswith(x, "```"), withbounds)
  backslash_removed = map(x -> replace(x, r"\\", ""), withoutbounds)

  tempfile = joinpath(tempdir(), "__tmp.jl")
  write(tempfile, backslash_removed)
  include(tempfile)
end

run_doctests(joinpath(Pkg.dir("ChainMap"), "src", "doc.jl"))
run_doctests(joinpath(Pkg.dir("ChainMap"), "docs", "src", "index.md"))

#Test.@test (@over 1) == 1
#
#Test.@test bitnot(1) == -2
#
#test_chain = @chain begin
  #1
  #+(1)
  #+(_, 1)
  #begin
    #a = 1 + _
    #a
  #end
  #sum
#end
#
#Test.@test test_chain == 4
#
#test_more = @chain begin
  #(1, 2)
  #+(_...)
#end
#
#Test.@test test_more == 3
#
#_ = 1
#
#test_ = @chain begin
  #_
  #+(_, 1)
  #+(2)
#end
#
#Test.@test test_ == 4
#
#test_function = @lambda @chain begin
  #+(_, 1)
  #+(2)
#end
#
#Test.@test test_function(1) == 4
#
#test_chain_function = @lambda @chain -(2, _) +(1)
#
#Test.@test test_chain_function(1) == 2
#
#test_map = @chain begin
  #1
  #begin x -> x^2 + _ end
  #map([1, 2])
#end
#
#Test.@test test_map == [2, 5]
#
#both = @over @chain begin
  #~[1,2]
  #+(1)
  #+(2)
#end
#
#Test.@test both == [4, 5]
#
#chain_tuple = @chain begin
  #1
  #(2, 3)
#end
#
#Test.@test chain_tuple == (1, 2, 3)
#
#readme = @lambda @over @chain begin
  #~_
  #-(1)
  #^(2, _)
  #begin
    #a = _ - 1
    #b = _ + 1
    #(a, b)
  #end
  #sum
#end
#
#Test.@test readme([1, 2]) == [2, 4]
#
#a = ( [1, 2], [3, 4] )
#dots_test = @over +( ~(a...) )
#Test.@test dots_test == [4, 6]
#
#b = ( [5, 6], [7, 8] )
#
#errrror =
  #try
    #ChainMap.over!( :( +( ~(a...), ~(b...) ) ) )
  #catch x
  #  x
  #end

#Test.@test errrror.msg == "Cannot map over more than one splatted argument"


#test1 = Arguments(1, 2, a = 3, b = 4)
#test2 = push(test1, 5, 6; c = 7, d = 8 )
#d = Dict{Symbol, Any}([(:c, 7), (:a, 3), (:b, 4), (:d, 8)])
#Test.@test test2 == Arguments((1,2,5,6), d)
#
#test_function_2(a, b, c; d = 4) = a - b + c - d
#
#test_arguments = @chain begin
  #1
  #Arguments()
  #push(2, d = 2)
  #unshift(3)
  #run(test_function_2)
#end
#
#Test.@test test_arguments == test_function_2(3, 1, 2; d = 2)
#
#a = [1, 2]
#b = @chain a push(1) unshift(2)
#Test.@test a != b

#errror =
#  try
#    ChainMap.safe(:hello)
#  catch x
#    x
#  end

#Test.@test errror.msg == "suffixed must end in suffix"

#c = ChainMap.chain
#o = ChainMap.over
#l = ChainMap.lambda
#@nonstandard c o l
#
#alias_test = @c begin
  #1
  #+(2)
  #+(3)
#end

#Test.@test alias_test == 6
