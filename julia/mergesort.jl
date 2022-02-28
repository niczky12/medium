"""
MergeSort in Julia
"""

using BenchmarkTools
import Random


Random.seed!(42)
x = rand(5) .* 10

x = rand(10000) .* 100

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

function merge_sort!(v)
    if length(v) > 1
        midpoint = length(v) ÷ 2
        left = v[1:midpoint]
        right = v[midpoint+1:end]
        merge_sort!(left)
        merge_sort!(right)

        left_index = 1
        right_index = 1
        new_index = 1

        while new_index <= length(v)
            if left_index > length(left)
                v[new_index] = right[right_index]
                right_index += 1
            elseif right_index > length(right)
                v[new_index] = left[left_index]
                left_index += 1
            elseif left[left_index] < right[right_index]
                v[new_index] = left[left_index]
                left_index += 1
            else
                v[new_index] = right[right_index]
                right_index += 1
            end
            new_index += 1
        end
    end
end

merge_sort!(x)

Base.Sort.MergeSortAlg


Random.seed!(42)
x = rand(10000) .* 100
@benchmark merge_sort(x)
@benchmark merge_sort!(x)




function merge_sort2!(v::AbstractVector, lo::Integer, hi::Integer, t=similar(v, 0))
    @inbounds if lo < hi
        m = (lo + hi) ÷ 2
        (length(t) < m-lo+1) && resize!(t, m-lo+1)

        merge_sort2!(v, lo,  m, t)
        merge_sort2!(v, m+1, hi, t)

        i, j = 1, lo
        while j <= m
            t[i] = v[j]
            i += 1
            j += 1
        end

        i, k = 1, lo
        while k < j <= hi
            if v[j] <= t[i]
                v[k] = v[j]
                j += 1
            else
                v[k] = t[i]
                i += 1
            end
            k += 1
        end
        while k < j
            v[k] = t[i]
            k += 1
            i += 1
        end
    end

    return v
end

function merge_sort2(v)
    temp_v = copy(v)
    merge_sort2!(temp_v, 1, length(v))
    return temp_v
end



@benchmark merge_sort2(x)
