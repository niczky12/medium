# start with this
using ProgressLogging

# need to click icon at bottom. this shows percentage
# if disabled, you just get an evaluating... section
# turning it on or off in the settings `Julia: Use Progress Fontend` will make it crash
@progress for i in 1:100
    sleep(0.1)
end


# alternative
using ProgressBars


for i in ProgressBar(1:100) #wrap any iterator
    sleep(0.1)
end


 for i in tqdm(1:100) #wrap any iterator
    sleep(0.1)
 end


iter = ProgressBar(1:100)
# the printer doens't update the decimals!!!
for i in iter
    # ... Neural Network Training Code
    sleep(0.1)
    loss = exp(-i)
    set_multiline_postfix(iter,
        "i: $i\nLinear: $(i/100)\nLog: $(log10(i)/2)")
end

using Printf
for i in iter
    # ... Neural Network Training Code
    sleep(0.1)
    loss = exp(-i)
    line_to_print = @sprintf("i: %d\nLinear: %2.2f\nLog: %2.2f", i, i/100, log10(i)/2)

    set_multiline_postfix(iter,
        line_to_print)
end



# parallel for loops
a = []
Threads.@threads for i in ProgressBar(1:1000)
  push!(a, i * 2)
end


# show how to calculate rolling loop times
# average past 10 iteration times

fib(n) = n < 2 ? 1 : fib(n - 2) * fib(n - 1)


a = time()
a2 = time()

mutable struct TimeRecorder
    slots::Vector{Float64}
    size::Int64
    current_iter::Float64

    function TimeRecorder(n)
        new(Vector{Float64}(), n, zero(Float64))
    end
end


function start!(t::TimeRecorder)
    t.current_iter != 0 && throw(ArgumentError("Already in iteration."))

    t.current_iter = time()
end

function Base.push!(t::TimeRecorder, new_time)
    if length(t.slots) == t.current_iter
        popfirst!(t.slots)
    end

    push!(t.slots, new_time)
end


function finish!(t::TimeRecorder)
    t.current_iter == 0 && throw(ArgumentError("Out of iteration, start the recorder first."))
    push!(t, time() - t.current_iter)
    t.current_iter = zero(Float64)
end

function value(t::TimeRecorder)
    sum(t.slots) / length(t.slots)
end



recorder = TimeRecorder(10)

iter = ProgressBar(1:50)

using Printf

for i in iter
    start!(recorder)
    fib(i)
    finish!(recorder)

    set_postfix(iter, rolling_time=@sprintf("%.2f", value(recorder)))
end
