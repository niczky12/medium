# Julia command line implementation of the 2048 game

using Test
import Random
import StatsBase
using Crayons

"""
    Push the items to the side of the line or row.
"""
function push_line(line; rev=false)
    
    new_line = similar(line)
    valid_numbers = collect(skipmissing(line))
    n = length(valid_numbers)

    if !rev
        new_line[end-n+1:end] .= valid_numbers
    else
        new_line[1:n] .= valid_numbers
    end

    return new_line
end


@test isequal(push_line([missing, missing, 1, missing]), [missing, missing, missing, 1])
@test isequal(push_line([1, 2, 3]), [1, 2, 3])
@test !isequal(push_line([3, 2, 1]), [1, 2, 3])
@test isequal(push_line([1, 3, 1]), [1, 3, 1])
@test isequal(push_line([3, missing, 2]), [missing, 3, 2])
@test isequal(push_line([3, missing, 2]; rev=true), [3, 2, missing])
@test isequal(push_line([missing, missing, missing]), [missing, missing, missing])
@test isequal(push_line([missing, missing, missing]; rev=true), [missing, missing, missing])


function push_board(board, direction::Symbol)
    @assert direction ∈ (:up, :down, :left, :right)

    new_board = copy(board)

    is_reversed = direction ∈ (:left, :up)
       
    n = size(board, 1)

    if direction in (:left, :right)
        for row_idx in 1:n
            new_board[row_idx, :] = push_line(board[row_idx, :]; rev=is_reversed)
        end
    else
        for col_idx in 1:n
            new_board[:, col_idx] = push_line(board[:, col_idx]; rev=is_reversed)
        end
    end

    return new_board
end

"""
    add_tile!(board)

    Modify and existing board by adding filling a new tile randomly.
    We pick from 3 possible values with different probabilities.
"""
function add_tile!(board)

    empty_cells = findall(ismissing, board)
    fill_position = StatsBase.sample(empty_cells)
    fill_value = StatsBase.sample(1:3, StatsBase.Weights([0.6, 0.3, 0.1]))

    board[fill_position] = fill_value
end


function initialise_board(n; seed=0)

    @assert n >= 2 "Board must have at least width of 2"

    if seed != 0
        Random.seed!(seed)
    end

    board = zeros(Union{Missing, Int64}, n, n)
    board .= missing

    for _ in 1:rand(1:n-1)
        add_tile!(board)
    end

    return board
end

@test all(initialise_board(2, seed=42) .=== [missing missing; 2 missing])


function merge_line(line; rev=false)

    n = length(line)
    l = copy(line)

    # rev is true for up and left directions
    reverser = rev ? identity : reverse

    for i in reverser(1:(n-1))
        if ismissing(l[i])
            continue
        end

        # we use === to handle the case if one is missing
        if l[i] === l[i + 1]
            if !rev
                l[i + 1] += 1
                l[i] = missing
            else
                # increment 1 tile and set remove the other
                l[i] += 1
                l[i + 1] = missing
            end
        end
    end

    return l
end

function merge_board(board, direction::Symbol)
    @assert direction ∈ (:up, :down, :left, :right)
    
    new_board = copy(board)
    is_reversed = direction ∈ (:up, :left)

    n = size(board, 1)

    if direction ∈ (:up, :down)
        for col_idx in 1:n
            new_board[:, col_idx] = merge_line(board[:, col_idx], rev=is_reversed)
        end

    else
        for row_idx in 1:n
            new_board[row_idx, :] = merge_line(board[row_idx, :], rev=is_reversed)
        end
    end
    return new_board
end


function swipe_board(board, direction::Symbol)

    new_board = push_board(board, direction)
    new_board = merge_board(new_board, direction)
    new_board = push_board(new_board, direction)

    return new_board
end

function centered_format(s, size, fill)

    l = length(s)
    right_chars = div(size - l, 2)
    left_chars = size - l - right_chars

    return "$(fill^left_chars)$s$(fill^right_chars)"
end


function print_box_part(value, part::Symbol)

    @assert part ∈ (:top, :middle, :bottom)

    # colours taken from DuckDuckGo's game
    colours = Dict(
        missing => Crayon(bold=true, foreground=:white, background=:white),
        1 => Crayon(bold=true, foreground=:white, background=(124,181,226)),
        2 => Crayon(bold=true, foreground=:white, background=(68,149,212)),
        3 => Crayon(bold=true, foreground=:white, background=(47,104,149)),
        4 => Crayon(bold=true, foreground=:white, background=(245,189,112)),
        5 => Crayon(bold=true, foreground=:white, background=(242,160,50)),
        6 => Crayon(bold=true, foreground=:white, background=(205,136,41)),
        7 => Crayon(bold=true, foreground=:white, background=(227,112,81)),
        8 => Crayon(bold=true, foreground=:white, background=(227,82,123)),
        9 => Crayon(bold=true, foreground=:white, background=(113,82,227)),
        10 => Crayon(bold=true, foreground=:white, background=(82,123,227)),
        11 => Crayon(bold=true, foreground=:white, background=(227,82,195)),
    )
    
    if ismissing(value)
        x = ""
    else
        x = "$(2 ^ value)"
    end

    parts = Dict(
        :top => centered_format("-", 12, '-'),
        :middle => "|$(centered_format(x, 10, ' '))|",
        :bottom => centered_format("-", 12, '-')
    )

    print(colours[value], parts[part])
end


function print_board(board)

    n = size(board, 1)

    for row_idx in 1:n
        for part in (:top, :middle, :bottom)
            for col_idx in 1:n
                value = board[row_idx, col_idx]
                print_box_part(value, part)
                print(Crayon(reset=true), " ")
            end
            println()
        end
        println()
    end
end


function print_score(board)
    score = sum(2 .^ skipmissing(board))
    n = size(board, 1)

    width = (14 * n) - length("Score: ")

    score_text = centered_format("Score: $score", width, ' ')
    println("\n$score_text\n")
end



# b = initialise_board(4)
# print_board(b)

have_lost(board) = findfirst(ismissing, board) === nothing


function game(n)

    board = initialise_board(n)

    input_mapping = Dict(
        'w' => :up,
        'd' => :right,
        's' => :down,
        'a' => :left)

    while true
        if have_lost(board)
            println("YOU LOST!")
            break
        elseif maximum(skipmissing(board)) == 11
            println("YOU WON!")
            break
        end

        # clear all output
        println("\33[2J")
        add_tile!(board)
        print_score(board)
        print_board(board)

        # wait for correct input
        user_input = 'i'
        while user_input ∉ keys(input_mapping)
            user_input = readline(keep=true)[1]
            print(user_input) 
        end

        direction = input_mapping[user_input]
        board = swipe_board(board, direction)
    end

    println("Final score: $(sum(2 .^ skipmissing(board)))")

end

game(3)
