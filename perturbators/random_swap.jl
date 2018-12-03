function random_swap(system::Vector{<:Real})
    l = length(system)
    start_index = rand(1:l-1)
    end_index = rand(start_index:l)

    return vcat(system[1:start_index-1], system[end_index-1:-1:start_index], system[end_index:end])
end

function point_swap(s::Vector{<:Real})
    system = copy(s)
    i = rand(1:length(system)-1)
    temp = system[i]
    system[i] = system[i+1]
    system[i+1] = temp
    return system
end
