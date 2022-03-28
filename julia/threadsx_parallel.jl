using Distributed
using ThreadsX
using BenchmarkTools
using Base.Threads
using Test
using Pipe: @pipe

Threads.nthreads()


ismultiple(n, d) = n % d == 0
ismultiple12(n) = ismultiple(n, 12)

@test ismultiple12(12)
@test ismultiple12(36)
@test !ismultiple12(13)
@test isapprox(mean(ismultiple12.(1:10000)), 1/12; atol=0.001)


# benchmarking single thread performance
N = 10_000

answer = sum(ismultiple12.(1:N))
# 9.559 μs
@btime sum(ismultiple12.(1:N))

iszero(rem(Integer(n), 2))



# even faster without broadcasting
# 6.002 μs
@btime sum(ismultiple12, 1:N)

function sumupto(n, fun)
	s = 0
	Threads.@threads for i in 1:n
		s += fun(i)
	end
	s
end

sum(sumupto(N, ismultiple12))

for _ in 1:10
	println(sumupto(N, ismultiple12))
end


res = @distributed (+) for i in 1:N
   ismultiple12(i)
end

@test res == answer

function sumupto_dist(fun, N)
    @distributed (+) for i in 1:N
        fun(i)
    end
end


# this is a lot slower than single threaded
# 31.545 μs
@btime sumupto_dist(ismultiple12, N)

# using ThreadsX
# 35.334 μs 
@test ThreadsX.sum(ismultiple12(i) for i in 1:N) == answer
# using list comprehension
@btime ThreadsX.sum(ismultiple12(i) for i in 1:N)
# using functional approach
@btime ThreadsX.sum(ismultiple12, 1:N)

############# making the function more taxing
# let's make our function more complicated
# number of prime divisors of each number summed up
import Primes

num_prime_divisors(n) = length(keys(Primes.factor(n)))

@test num_prime_divisors(1) == 0
@test num_prime_divisors(2) == 1
@test num_prime_divisors(3) == 1
@test num_prime_divisors(4) == 1
@test num_prime_divisors(12) == 2

answer_prime = sum(num_prime_divisors, 1:N)
# 2.862 ms
@btime sum(num_prime_divisors, 1:N)
# 2.889 ms 
@btime countupto_dist(num_prime_divisors, N)
# 585.658 μs
# that is 0.585658 ms, close to 6x speedup!
@btime ThreadsX.sum(num_prime_divisors, 1:N)


############# what else can ThreadsX do?
# exercism plug for scrabble exercise

# do scrabble score with mapreduce
value_to_letters = Dict(
    1 => ['A', 'E', 'I', 'O', 'U', 'L', 'N', 'R', 'S', 'T'],
    2 => ['D', 'G'],
    3 => ['B', 'C', 'M', 'P'],
    4 => ['F', 'H', 'V', 'W', 'Y'],
    5 => ['K', ],
    8 => ['J', 'X'],
    10 => ['Q', 'Z']
)

scores = Dict{Char, Int}()

for (value, letters) in value_to_letters
    for letter in letters
        scores[letter] = value
    end
end

scores


score(str) = mapreduce(letter -> get(scores, letter, 0), +, uppercase(str), init=0)

score("hello")

rj = @pipe "https://shakespeare.folger.edu/downloads/txt/romeo-and-juliet_TXT_FolgerShakespeare.txt" |>
    download |>
    readlines |>
    reduce(*, _)


# 7.7 ms
@btime score(romeo_and_juliet)

score_parallel(str) = ThreadsX.mapreduce(letter -> get(scores, letter, 0), +, uppercase(str), init=0)

# 2.3 ms
@btime score_parallel(romeo_and_juliet)


#### mention other functions
# MergeSort       any             findfirst       map!            reduce
# QuickSort       collect         findlast        mapreduce       sort
# Set             count           foreach         maximum         sort!
# StableQuickSort extrema         issorted        minimum         sum
# all             findall         map             prod            unique

# it can also do:
# using OnlineStats: Mean
#ThreadsX.reduce(Mean(), 1:10)
# Mean: n=10 | value=5.5
# would be nice to have this in a distributed table setting

a = collect(1:100)
# this needs an input array too, which can be the same array
ThreadsX.map!(i-> i^2, a, a)
a


ThreadsX.findall(ismultiple12, 1:100)