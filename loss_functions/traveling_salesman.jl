include("traveling_salesman_data.jl")

function score(params::Vector{Int}, data::Vector{Vector{Int}})
    total = 0.0
    for i in 1:length(params) - 1
        total += euc_distance(data[params[i]]..., data[params[i + 1]]...)
    end
    total += euc_distance(data[params[1]]..., data[params[end]]...)
    return(total)
end

function fast_score(params::Vector{Int}, data::Vector{Vector{Int}})
    return params[1]/params[2] + params[3]
end
