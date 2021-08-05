# estimating π using random numbers only
using Plots
import Random
using Distributions
using BenchmarkTools
using Printf

gr()


@show π
# area of unit circle = π
# area of square that can fit a unit circle (r = 1) = 4
# ratio of the two areas = π / 4

# unit circle: x^2 + y^2 = 1
# -> y = +- sqrt(1 - x^2)

square_points = [(-1, -1), (-1, 1), (1, 1), (1, -1), (-1, -1)]

plot(square_points, aspect_ratio=1.0, legend=false)
title!("The square")
xlabel!("x")
ylabel!("y")
savefig("figures/square.png")

plot!(x -> sqrt(1 - x^2); color="red")
plot!(x -> -sqrt(1 - x^2), color="red")
title!("The square with a unit circle")

# let's draw one random point uniformly from this square
Random.seed!(23)
v = rand(Uniform(-1,1), 2)
inside = sum(v .^ 2) <= 1

scatter!([v[1]], [v[2]])
scatter!([0.8], [0.7], color="blue")
savefig("figures/square_with_circle.png")

function pi_estimator(samples)
    inside_counter = 0
    distribution = Uniform(-1, 1)

    for _ in 1:samples
        v = rand(distribution, 2)
        if sum(v .^ 2) <= 1
            inside_counter += 1
        end
    end

    return 4inside_counter / samples
end

Random.seed!(42)
estimate = pi_estimator(10_000_000)
abs(π - estimate)

π


function record_estimates(n)

    estimates = zeros(Float64, n)
    samples = Array{Float64}[]
    
    inside_counter = 0
    distribution = Uniform(-1, 1)

    for i in 1:n
        v = rand(distribution, 2)
        push!(samples, v)
        if sum(v .^ 2) <= 1
            inside_counter += 1
        end
        estimates[i] = 4inside_counter / i
    end

    return estimates, samples
end

Random.seed!(1729)
estimates, samples = record_estimates(1000);
plot(estimates)

savefig("figures/pi_estimates.png")


plot(estimates; label="π̂")
hline!([π]; label="π")
xlabel!("Number of samples")
title!("Estimating π")

function plot_estimates(i, estimates)
    n = length(estimates)

    p = plot()
    xlims!(0, n)
    ylims!(2.5, 4.0)
    hline!([π]; label="π")
    plot!(1:i, estimates[1:i]; label="π̂")
    xlabel!("Number of samples")

    # calculate error
    current_estimate = estimates[i]
    estimate_error = abs(π - current_estimate)

    # add error and current estimate to plot as annotations
    annotate!((n*0.75, 2.7, (@sprintf("π̂=%.3f", current_estimate), 14, :red, :center)))
    annotate!((n*0.75, 2.6, (@sprintf("ϵ=%.3f", estimate_error), 14, :red, :center)))
    return p
end

plot_estimates(1000, estimates)

function plot_samples(i, samples)
    # draw a square and set our plotting surface
    square_points = [(-1, -1), (-1, 1), (1, 1), (1, -1), (-1, -1)]
    p = plot(square_points;
        xlim=(-1, 1), ylim=(-1, 1),
        color="black",
        aspect_ratio=1.0,
        title="Estimate π with random numbers\nand a circle...")

    # draw a circle. Remember that x^2 + y^2 = 1 gives a unit circle
    plot!(x -> sqrt(1 - x^2); color="red", legend=false)
    plot!(x -> -sqrt(1 - x^2), color="red", legend=false)

    # make older points more transparent by reducing their alpha values
    alphas = (collect(1:i) ./ i)

    # we only plot the first i points
    samples_to_plot = samples[1:i]
    
    # filter mask to figure out in circle and out of cirlce points
    in_circle = map(x -> sum(x.^2) <= 1, samples_to_plot)

    # points inside the circle are red
    scatter!(
        # this map, selects the x and y values from our array of points
        map(x -> x[1], samples_to_plot[in_circle]),
        map(x -> x[2], samples_to_plot[in_circle]),
        markeralpha=alphas[in_circle],
        markercolor="red")

    # those outside are blue
    scatter!(
        map(x -> x[1], samples_to_plot[.!in_circle]),
        map(x -> x[2], samples_to_plot[.!in_circle]),
        markeralpha=alphas[.!in_circle],
        markercolor="blue")

    return p
end


plot_samples(1000, samples)

# make it into a gif
Random.seed!(42)
n = 1000
estimates, samples = record_estimates(n)
anim = @animate for i ∈ 1:n
    p1 = plot_samples(i, samples)
    p2 = plot_estimates(i, estimates)
    plot(p1, p2)
end
gif(anim, "figures/anim_pi.gif", fps = 15)

