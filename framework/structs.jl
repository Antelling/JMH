struct ProblemInstance
    objective::Vector{Int}
    upper_bounds::Vector{Tuple{Vector{Int},Int}}
    lower_bounds::Vector{Tuple{Vector{Int},Int}}
    index::Int
end

BitList = Vector{Bool}

Swarm = Vector{BitList}

ImprovementPoints = Vector{Tuple{Int,Int,Int}}

function identity_repair(sol::BitList, problem::ProblemInstance)
    #because repair was called, we know it isn't valid
    return (false, sol)
end

function identity(x, y) return x end
