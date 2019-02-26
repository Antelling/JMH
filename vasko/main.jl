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
		ps = "$(problems)"
	    results = Dict{String,Vector{Tuple{Int,Float64}}}(
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

	    for problem in problems
	        println("")
	        println("testing problem #$(problem.index)")

			p = "$(problem)"

	        swarm = random_init(problem, 100, repair=false)
	        for alg in [TBO_prob, jaya, TBO_med, LBO]
				start_time = time_ns()
	            _, best_score = iterate_alg(alg, deepcopy(swarm), problem, repair=true)
				end_time = time_ns()
				elapsed_time = (end_time - start_time)/(10^9)
	            println("  $(alg)_repair found max score of $(best_score) in $(elapsed_time) seconds")
	            push!(results["$(alg)_repair"], (best_score, elapsed_time))
	        end

			start_time = time_ns()
	        cur_swarm, best_score = walk_through_algs([jaya, TBO_med, LBO], deepcopy(swarm), problem, repair=true, verbose=1)
			end_time = time_ns()
			println(best_score)
			println(find_best_score(cur_swarm, problem))
			@assert best_score == find_best_score(cur_swarm, problem)
			elapsed_time = (end_time - start_time)/(10^9)
	        println("  triplicate_med_repair found max score of $(best_score) in $(elapsed_time) seconds")
	        push!(results["triplicate_med_repair"], (best_score, elapsed_time))

			start_time = time_ns()
			cur_swarm, best_score = walk_through_algs([jaya, TBO_prob, LBO], deepcopy(swarm), problem, repair=true, verbose=1)
			end_time = time_ns()
			println(best_score)
			println(find_best_score(cur_swarm, problem))
			@assert best_score == find_best_score(cur_swarm, problem)
			elapsed_time = (end_time - start_time)/(10^9)
	        println("  triplicate_prob_repair found max score of $(best_score) in $(elapsed_time) seconds")
	        push!(results["triplicate_prob_repair"], (best_score, elapsed_time))


			for alg in [jaya, TBO_prob, TBO_med, LBO]
				start_time = time_ns()
	            _, best_score = iterate_alg(alg, deepcopy(swarm), problem, repair=false)
				end_time = time_ns()
				elapsed_time = (end_time - start_time)/(10^9)
	            println("  $(alg)_no_repair found max score of $(best_score) in $(elapsed_time) seconds")
	            push!(results["$(alg)_no_repair"], (best_score, elapsed_time))
	        end

			start_time = time_ns()
	        _, best_score = walk_through_algs([jaya, TBO_med, LBO], deepcopy(swarm), problem, repair=false)
			end_time = time_ns()
			elapsed_time = (end_time - start_time)/(10^9)
	        println("  triplicate_med_no_repair found max score of $(best_score) in $(elapsed_time) seconds")
	        push!(results["triplicate_med_no_repair"], (best_score, elapsed_time))

			start_time = time_ns()
	        _, best_score = walk_through_algs([jaya, TBO_prob, LBO], deepcopy(swarm), problem, repair=false)
			end_time = time_ns()
			elapsed_time = (end_time - start_time)/(10^9)
	        println("  triplicate_prob_no_repair found max score of $(best_score) in $(elapsed_time) seconds")
	        push!(results["triplicate_prob_no_repair"], (best_score, elapsed_time))

			open("results/dataset_timed_repair_$(dataset).json", "w") do f
	        	write(f, JSON.json(results, 4))
	    	end

			@assert p == "$(problem)"
	    end

		@assert ps == "$(problems)"
	end
end

main()
