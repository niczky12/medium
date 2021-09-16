using Flux
using Dates
import Random


Random.seed!(1729)


last_train_epoch = datetime2unix(DateTime("2020-12-31T23:59:59"))
first_train_epoch = 0.0

y = rand(first_train_epoch:1.0:last_train_epoch, 100)
ys = collect(eachrow(reshape(y, 100, 1)))

# split x's into year, month, day, hour, minute, seconds as inputs
function datetime2input(x)
    Float64.([year(x), month(x), day(x), hour(x), minute(x), second(x)])
end


function normalizer(v)
    (v .- minimum(v)) / (maximum(v) - minimum(v))
end


xs = collect(eachrow(mapslices(normalizer, x, dims=1)))

model = Chain(
    Dense(6, 10, σ),
    Dense(10, 10, σ),
    Dense(10, 1, relu))


params(model)

#Our loss function to minimize
loss(x, y) = Flux.mse(model(x), y)

optimizer = ADAM()

model(xs[1])
model.layers[1].W

for epoch in 1:10000
    Flux.train!(loss, params(model), zip(xs, ys), optimizer)
    epoch % 1000 == 0 && println(sum(loss.(xs, ys)))
end



x = datetime2input.(now())

Flux.params(model)

model(x[2])
