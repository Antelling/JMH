include("parse_data.jl")
const problems = parse_file("data/mdmkp_ct1.txt")

include("initial_pop.jl")
include("eval_solution.jl")
include("eval_problem.jl")
include("repair_op.jl")

include("alg_coordinator.jl")
include("jaya.jl")
include("tlbo.jl")

import JSON

for dataset in 1:9
    problems = parse_file("data/mdmkp_ct$(dataset).txt")
    results = Dict{String,Vector{Int}}("jaya"=>[],"TBO_prob"=>[],"TBO_med"=>[],"LBO"=>[], "triplicate"=>[])
    for problem in problems
        println("")
        println("testing problem #$(problem.index)")

        p = "$(problem)"

        swarm = random_init(problem, 100, repair=false)
        for alg in [jaya, TBO_prob, TBO_med, LBO]
            _, best_score = iterate_alg(alg, deepcopy(swarm), problem)
            println("  $(alg) found max score of $(best_score)")
            push!(results["$(alg)"], best_score)
        end

        _, best_score = walk_through_algs([jaya, TBO_med, LBO], swarm, problem)
        println("  triplicate found max score of $(best_score)")
        push!(results["triplicate"], best_score)

        @assert p == "$(problem)" #assure we don't have any more mutation
    end
    open("results/dataset_$(dataset).json", "w") do f
        write(f, JSON.json(results))
    end
end