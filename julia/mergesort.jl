"""
MergeSort in Julia
"""

using BenchmarkTools
import Random


Random.seed!(42)
x = rand(5) .* 10

# x = rand(10000) .* 100

# @benchmark sort(x)
# @benchmark sort(x, alg=MergeSort)


function merge_sort(v)
    length(v) == 1 && return v

    midpoint = length(v) ÷ 2
    left = merge_sort(v[1:midpoint])
    right = merge_sort(v[(midpoint+1):end])

    left_index = 1
    right_index = 1
    new_index = 1
    new_array = copy(v)

    while new_index <= length(new_array)
        # we exhauseted the left array
        if left_index > length(left)
            new_array[new_index] = right[right_index]
            right_index += 1
        elseif right_index > length(right)
            new_array[new_index] = left[left_index]
            left_index += 1
        elseif left[left_index] < right[right_index]
            new_array[new_index] = left[left_index]
            left_index += 1
        else
            new_array[new_index] = right[right_index]
            right_index += 1
        end
        new_index += 1
    end

    return new_array
end

merge_sort(x)

@benchmark merge_sort(x)


