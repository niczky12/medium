# Julia command line implementation of the 2048 game

using Test
import Random
using Crayons

# board is a simple nxn matrix

"""
    Merge the compatible items together on one line.
"""
function merge(row)
    return
end


"""
    Push the items to the side of the line or row.
"""
function push_line(line; reverse=false)
    
    new_line = similar(line)
    valid_numbers = collect(skipmissing(line))
    n = length(valid_numbers)

    if !reverse
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
@test isequal(push_line([3, missing, 2]; reverse=true), [3, 2, missing])
@test isequal(push_line([missing, missing, missing]), [missing, missing, missing])
@test isequal(push_line([missing, missing, missing]; reverse=true), [missing, missing, missing])


function push_board(board, direction::Symbol)
    new_board = copy(board)

    reverse = direction ∈ (:left, :up)
       
    n = size(board, 1)

    if direction in (:left, :right)
        for i in 1:n
            new_board[i, :] = push_line(board[i, :]; reverse=reverse)
        end
    else
        for i in 1:n
            new_board[:, i] = push_line(board[:, i]; reverse=reverse)
        end
    end

    return new_board
end

function initialise_board(n; seed=0)

    @assert n >= 2 "Board must have at least width of 2"

    if seed != 0
        Random.seed!(seed)
    end

    board = zeros(Union{Missing, Int64}, n, n)
    board .= missing

    num_cells = n^2
    num_fill_cells = rand(1:n-1)
    fill_cell_pos = Random.randperm(num_cells)[1:num_fill_cells]
    fill_cell_val = Random.rand(0:2, num_fill_cells)

    board[fill_cell_pos] .= fill_cell_val
    return board
end

b = initialise_board(3; seed=42)

push_board(b, :left)
push_board(b, :right)
push_board(b, :up)
push_board(b, :down)


b[1, :]
b[:, 1]

function merge_line(line)

    n = length(line)
    l = copy(line)

    for i in 1:(n-1)
        if ismissing(l[i])
            continue
        end

        if l[i] === l[i + 1]
            l[i] += 1
            l[i + 1] = missing
        end
    end

    return l
end

line = b[1, :]
line[1] = 1
line[2] = 1

merge_line(line)

function merge_board(board, direction::Symbol)
    @assert direction ∈ (:up, :down, :left, :right)
    
    new_board = copy(board)

    n = size(board, 1)

    if direction ∈ (:up, :down)
        for column_idx in 1:n
            new_board[:, column_idx] = merge_line(board[:, column_idx])
        end

    else
        for row_idx in 1:n
            new_board[row_idx, :] = merge_line(board[row_idx, :])
        end
    end
    return new_board
end

b[2, 2] = 1
b[3, 1] = 1


merge_board(b, :up)
merge_board(b, :right)

function swipe_board(board, direction::Symbol)

    new_board = push_board(board, direction)
    new_board = merge_board(new_board, direction)
    new_board = push_board(new_board, direction)

    return new_board
end


swipe_board(b, :left)
swipe_board(b, :right)
swipe_board(b, :down)
swipe_board(b, :up)





b1 = "/------\\\n| 2048 |\n\\------/"

print(Crayon(background=:blue, foreground=:black), b1)


# doesn't support centering of text
# import Format


function centered_format(s, size, fill)

    l = length(s)
    right_chars = div(size - l, 2)
    left_chars = size - l - right_chars

    return "$(fill^left_chars)$s$(fill^right_chars)"
end


function print_box_part(value, part::Symbol)

    @assert part ∈ (:top, :middle, :bottom)

    if ismissing(value)
        x = ""
    else
        x = "$(2 ^ value)"
    end

    parts = Dict(
        :top => "/----------\\",
        :middle => "|$(centered_format(x, 10, ' '))|",
        :bottom => "\\----------/"
    )

    print(parts[part])
end


print_box_part(4, :top)
print_box_part(4, :middle)
print_box_part(4, :bottom)

c = Crayon(background=:green)
text = "hello"

xs = (c, text)
xy = (text,)

print(xs...)
print(xy...)


function print_score(board)
    score = sum(2 .^ skipmissing(board))
    n = size(board, 1)

    width = (14 * n) - length("Score: ")

    score_text = centered_format("Score: $score", width, ' ')
    println("\n$score_text\n")
end



function print_board(board)

    n = size(board, 1)

    for row_idx in 1:n
        for part in (:top, :middle, :bottom)
            for col_idx in 1:n
                value = board[row_idx, col_idx]
                print_box_part(value, part)
                print(" ")
            end
            print("\n")
        end
        print("\n")
    end
end

print_score(b)
print_board(b)

for board_n in 2:6
    b2 = initialise_board(board_n)
    print_score(b2)
    print_board(b2)
end
