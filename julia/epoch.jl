using Flux
using Dates
import Random
using IterTools


Random.seed!(1729)


first_train_epoch =  datetime2unix(DateTime("2010-01-01T00:00:00"))
last_train_epoch = datetime2unix(DateTime("2020-12-31T23:59:59"))
last_test_epoch = datetime2unix(DateTime("2030-12-31T23:59:59"))


function y_normaliser(y)
    (y - first_train_epoch) / (last_test_epoch - first_train_epoch)
end

function y_rescaler(y_predict)
    y_predict * (last_test_epoch - first_train_epoch) + first_train_epoch
end



# split x's into year, month, day, hour, minute, seconds as inputs
function datetime2input(x)
    Float64.([(year(x) - 2010) / 30, month(x) / 12, day(x) / 31, hour(x) / 24, minute(x) / 60, second(x) / 60])
end



# i will need to normalise not only the inputs but also the outputs as they are on a huge scale difference
y = rand(first_train_epoch:1.0:last_train_epoch, 100)
ys = y_normaliser.(y)


xs = datetime2input.(unix2datetime.(y))
model = Dense(6, 1, identity)


# create minibatches
batch_size = 10
xs = hcat.(partition(xs, batch_size)...)
ys = hcat.(partition(ys, batch_size)...)


model = Dense(6, 1, identity)


model = Chain(
    Dense(6, 8, σ),
    Dense(8, 8, σ),
    Dense(8, 1, identity)
)


#Our loss function to minimize
loss(x, y) = Flux.mse(model(x), y)
optimizer = ADAM()


for epoch in 1:1000
    Flux.train!(loss, params(model), zip(xs, ys), optimizer)
    if epoch % 10 == 0
        @show sum(loss.(xs, ys))
        # @show params(model)
        # @show model(xs[1]) ys[1]
    end
end


function predict_epoch(dt)
    y_rescaler(model(datetime2input(dt))[1])
end


for y in y
    dt = unix2datetime(y)
    pred_dt = unix2datetime(predict_epoch(dt))
    diff = round(pred_dt - dt, Hour)
    println("$dt -> $pred_dt | difference: $diff")
end


Random.seed!(42);
y_test = rand(last_train_epoch:1.0:last_test_epoch, 100);

for y in y_test
    dt = unix2datetime(y)
    pred_dt = unix2datetime(predict_epoch(dt))
    diff = round(pred_dt - dt, Hour)
    println("$dt -> $pred_dt | difference: $diff")
end
