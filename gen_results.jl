include("parse_data.jl")

include("initial_pop.jl")
include("eval_solution.jl")
include("eval_problem.jl")
include("repair_op.jl")

include("alg_coordinator.jl")
include("jaya.jl")
include("tlbo.jl")

import JSON


const optimals = JSON.parse(read(open("data/optimal.json"), String))

function calc_percent(observed::Real, expected::Real)
	return (expected - observed)/expected
end

function main()
	alg  = triplicate_monad([
				jaya_monad(repair=true, repair_op=VSRO),
				TBO_monad(repair=true, repair_op=VSRO, prob=true),
				LBO_monad(repair=true, repair_op=VSRO)])
	for dataset in [8]
	    problems = parse_file("data/mdmkp_ct$(dataset).txt")
		results::Vector{Vector{Real}} = []

	    for (i, problem) in enumerate(problems)
			swarm = dimensional_focus(problem, 50)

			start_time = time_ns()
			cur_swarm, best_score = alg(swarm, problem)
			end_time = time_ns()
			elapsed_time = (end_time - start_time)/(10^9)
	        println("triplicate_prob_repair found max score of $(best_score) in $(elapsed_time) seconds")
	        push!(results, [best_score, calc_percent(best_score, optimals[string(dataset)][i]), elapsed_time])

			open("results/only_triplicate_$(dataset)_good.json", "w") do f
	        	write(f, JSON.json(results, 4))
	    	end
	    end
	end
end

main()
