using Memoize
using BenchmarkTools


# naive fibonacci
function fibonacci(n)
    if n <= 2
        return 1
    else
        return fibonacci(n - 2) + fibonacci(n - 1)
    end
end

fibonacci(n) = n <= 2 ? 1 : fibonacci(n - 2) + fibonacci(n - 1)

for i in 1:10
    @show i, fibonacci(i)
end


@btime fibonacci(30)


function fibonacci_memory(n, memory=Dict(1 => 1, 2 => 1))
    if n in keys(memory)
        return memory[n]
    end

    result = fibonacci_memory(n - 2, memory) + fibonacci_memory(n - 1, memory)
    memory[n] = result
    return result
end


@btime fibonacci_memory(30)

@memoize function fibonacci_easy(n)
    if n <= 2
        return 1
    else
        return fibonacci_easy(n -2) + fibonacci_easy(n - 1)
    end
end

@time fibonacci_easy(30)
@btime fibonacci_memory(100)


function fib(n)    
    a, b = 1, 1
    for _ in 3:n
        a, b = b, a + b
    end
    return b
end

for i in 1:10
    @show i, fibonacci(i), fib(i)
end


@btime fib(30)