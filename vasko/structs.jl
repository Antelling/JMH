struct ProblemInstance
    objective::Vector{Int}
    upper_bounds::Vector{Tuple{Vector{Int},Int}}
    lower_bounds::Vector{Tuple{Vector{Int},Int}}
    index::Int
end

BitList = Vector{Bool}

Swarm = Vector{BitList}

function Pass() end #used when strong typing prevents not having an optional function
