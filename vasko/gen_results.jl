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
		results::Vector{Int} = []

	    for problem in problems[1:6:90]
			swarm = random_init(problem, 100, repair=false)

			start_time = time_ns()
			cur_swarm, best_score = walk_through_algs([jaya, TBO_prob, LBO], deepcopy(swarm), problem, repair=true, repair_op=VSRO, verbose=1)
			end_time = time_ns()
			elapsed_time = (end_time - start_time)/(10^9)
	        println("triplicate_prob_repair found max score of $(best_score) in $(elapsed_time) seconds")
	        push!(results, best_score)

			open("results/only_triplicate_$(dataset).json", "w") do f
	        	write(f, JSON.json(results, 4))
	    	end
	    end
	end
end

main()
