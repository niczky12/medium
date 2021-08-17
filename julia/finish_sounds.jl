using WAV

# let's get some sounds
# sounds dources from: https://themushroomkingdom.net/media/smb/wav
sounds_source = Dict(
    "game_over" => "https://themushroomkingdom.net/sounds/wav/smb/smb_gameover.wav",
    "stage_clear" => "https://themushroomkingdom.net/sounds/wav/smb/smb_stage_clear.wav",
    "coin" => "https://themushroomkingdom.net/sounds/wav/smb/smb_coin.wav"
)

mkpath("data")
for (fname, link) in sounds_source
    download(link, "data/$fname.wav")
end

sounds = Dict(
    (key, wavread("data/$key.wav")) for key in keys(sounds_source)
)

# sounds["game_over"]
# wavplay(sounds["game_over"][1], sounds["game_over"][2])

function beep(sound)
    wavplay(sounds[sound][1], sounds[sound][2])
end


macro beep(expression, sound)
    res = eval(expression)
    beep(sound) 
    return res
end

# set default sound to coin
macro beep(expression)
    return :( @beep $expression "coin")
end

# function that takes long time to run for testing
fib(n) = n < 2 ? 1 : fib(n-2) + fib(n-1)

@beep 10
@beep fib(40) "game_over"
@beep fib(40) "coin"
@beep fib(40)
