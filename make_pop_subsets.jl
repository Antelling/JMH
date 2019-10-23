include("framework/structs.jl")
include("framework/load_datasets.jl")
include("framework/problem_properties.jl")
include("framework/solution_validity.jl")
include("framework/swarm_properties.jl")

include("algorithms/repair_op.jl")
include("algorithms/hybrids.jl")
include("algorithms/gen_initial_pop.jl")
include("algorithms/alg_coordinator.jl")
include("algorithms/jaya.jl")
include("algorithms/tlbo.jl")
include("algorithms/ga.jl")
include("algorithms/local_search.jl")

import JSON

function make_random_subset(population::Swarm, problem::ProblemInstance, n::Int)::Swarm
    perm = randperm(length(population))[1:n]
    return [population[i] for i in perm]
end

function take_best_subset(population::Swarm, problem::ProblemInstance, n::Int)
    scored_solutions::Vector{Tuple{BitList,Int}} = []
    for sol in population
        score = score_solution(sol, problem)
        push!(scored_solutions, tuple(sol, score))
    end
    sort!(scored_solutions, by=x->-x[2])
    return [scored_solutions[i][1] for i in 1:n]
end

import Distances
function make_diverse_subset(population::Swarm, problem::ProblemInstance, n::Int)
    scored_solutions::Vector{Tuple{BitList,Int}} = []
    for sol in population
        score = score_solution(sol, problem)
        push!(scored_solutions, tuple(sol, score))
    end
    sort!(scored_solutions, by=x->-x[2])

    #first we take the best solution, and put it in the selected set
    selected::Swarm = []
    max_score = scored_solutions[1][2]
    push!(selected, pop!(scored_solutions)[1])
    #we now know the maximum score
    #we also know the maximum distance this population can have is from
    #000...000 to 111...111
    min_corner = zeros(length(selected[1]))
    max_corner = ones(length(selected[1]))
    max_distance = Distances.euclidean(min_corner, max_corner)

    while length(selected) < n
        min_heuristic_scores::Vector{Float64} = []
        for sol in scored_solutions
            heuristic_scores = [(sol[2]/max_score)*(Distances.euclidean(sol[1], sel_sol)/max_distance) for sel_sol in selected]
            push!(min_heuristic_scores, findmin(heuristic_scores)[1])
        end
        score, index = findmax(min_heuristic_scores)
        push!(selected, scored_solutions[index][1])
        deleteat!(scored_solutions, index)
    end

    return selected
end

function main()
    for file in 1:9
        println("generating for file $file")
        filename = "beasley_mdmkp_datasets/initial_pop/$(file)_pop180_ls_decimated.json"
        data::Vector{Swarm} = JSON.parsefile(filename)
        problems = parse_file("beasley_mdmkp_datasets/mdmkp_ct$(file).txt")
        problems = [decimate_lowerbounds(problem) for problem in problems]
        blah = []
        for size in [30, 60, 90, 120, 150, 180]
            print("size is: $size... ")
            for i in 1:90
                push!(blah, make_random_subset(data[i], problems[i], size))
            end
            open("beasley_mdmkp_datasets/dec_pop_subsets/$(file)_rand$(size).json", "w") do f
                write(f, JSON.json(blah))
            end
        end
    end
end

main()
