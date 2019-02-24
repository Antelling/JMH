include("parse_data.jl")

include("initial_pop.jl")
include("eval_solution.jl")
include("eval_problem.jl")
include("repair_op.jl")

include("alg_coordinator.jl")
include("jaya.jl")
include("tlbo.jl")

import JSON

function main()
	for dataset in [1]
	    problems = parse_file("data/mdmkp_ct$(dataset).txt")
	    results = Dict{String,Vector{Int}}(
			"jaya_repair"=>[],
			"TBO_prob_repair"=>[],
			"TBO_med_repair"=>[],
			"LBO_repair"=>[],
			"triplicate_prob_repair"=>[],
			"triplicate_med_repair"=>[],
			"jaya_no_repair"=>[],
			"TBO_prob_no_repair"=>[],
			"TBO_med_no_repair"=>[],
			"LBO_no_repair"=>[],
			"triplicate_prob_no_repair"=>[],
			"triplicate_med_no_repair"=>[]
		)

	    for problem in problems[1:10]
	        println("")
	        println("testing problem #$(problem.index)")

	        #p = "$(problem)"

	        swarm = random_init(problem, 100, repair=false)
	        for alg in [jaya, TBO_prob, TBO_med, LBO]
	            _, best_score = iterate_alg(alg, deepcopy(swarm), problem, repair=true)
	            println("  $(alg) found max score of $(best_score)")
	            push!(results["$(alg)_repair"], best_score)
	        end

	        _, best_score = walk_through_algs([jaya, TBO_med, LBO], swarm, problem, repair=true)
	        println("  triplicate found max score of $(best_score)")
	        push!(results["triplicate_med_repair"], best_score)

			_, best_score = walk_through_algs([jaya, TBO_prob, LBO], swarm, problem, repair=true)
	        println("  triplicate found max score of $(best_score)")
	        push!(results["triplicate_prob_repair"], best_score)


			for alg in [jaya, TBO_prob, TBO_med, LBO]
	            _, best_score = iterate_alg(alg, deepcopy(swarm), problem, repair=false)
	            println("  $(alg) found max score of $(best_score)")
	            push!(results["$(alg)_no_repair"], best_score)
	        end

	        _, best_score = walk_through_algs([jaya, TBO_med, LBO], swarm, problem, repair=false)
	        println("  triplicate found max score of $(best_score)")
	        push!(results["triplicate_med_no_repair"], best_score)

			_, best_score = walk_through_algs([jaya, TBO_prob, LBO], swarm, problem, repair=false)
	        println("  triplicate found max score of $(best_score)")
	        push!(results["triplicate_prob_no_repair"], best_score)

	        #@assert p == "$(problem)" #assure we don't have any more mutation
			#open("results/dataset_with_repair_$(dataset).json", "w") do f
	        #	write(f, JSON.json(results))
	    	#end

	    end
	end
end

#main()
