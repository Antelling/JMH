function assert_no_duplicates(swarm::Swarm)
    for (i::Int, a::BitList) in enumerate(swarm)
        for (j::Int, b::BitList) in enumerate(swarm)
            @assert (i == j || a != b)
        end
    end
end

function find_best_solution(swarm::Swarm, problem::ProblemInstance)
    best_score::Int = 0
    best_solution::BitList = []
    for solution in swarm
        if score_solution(solution, problem) > best_score
            best_score = score_solution(solution, problem)
            best_solution = solution
        end
    end
    return best_solution
end

function find_worst_solution(swarm::Swarm, problem::ProblemInstance)
    worst_score::Int = score_solution(swarm[1], problem) + 1
    worst_solution::BitList = []
    for solution in swarm
        if score_solution(solution, problem) < worst_score
            worst_score = score_solution(solution, problem)
            worst_solution = solution
        end
    end
    return worst_solution
end

import Distances
"""calculate the distance matrix from the provided metric. Then, for every point, take its least n distances and
add them to a total. Return the total."""
function diversity_metric(swarm::Swarm; metric::Distances.PreMetric=Distances.Euclidean(), n::Int=3)
    matrix::Array{Int, 2} = reduce(hcat, swarm) #turn list of bitlist into a matrix of bitlist
    R = Distances.pairwise(metric, matrix, matrix, dims=2) #generate pairwise distance matrix
                    #this is a symmetrical matrix with 0 down the diagonal from top left to bottom right
    rows::Vector{Vector{Float64}} = collect(eachrow(R)) #turn back into list of lists
    map(sort!, rows) #sort rows so lowest distances come first
    rows = [row[2:n+1] for row in rows] #first item of row will be zero, so take from second element to n+1 elements.
                                        #julia has 1 based indexing
    total_distances = sum(sum(rows))
    amount_of_distances = n*length(swarm)
    return total_distances/amount_of_distances
end
