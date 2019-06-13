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
using Dates: today
# import Random

const problems_dir = "beasley_mdmkp_datasets/"
const results_dir = "results/TBO_exploration/"

function main(;verbose::Int=0)
	for dataset in [3, 4, 5]
	    problems = parse_file(problems_dir * "mdmkp_ct$(dataset).txt")
		if verbose > 0
			ps = "$(problems)"
		end
		n_fails = 25
		time_limit = 4
		algorithms = [(control_monad(), "control"),
			(iterate_monad(TBO_monad(local_search=VND, top_n=1), n_fails=n_fails, time_limit=time_limit), "T1_ls"),
			(iterate_monad(TBO_monad(local_search=VND, top_n=3), n_fails=n_fails, time_limit=time_limit), "T3_ls"),
			(iterate_monad(CBO_monad(local_search=VND, bottom_n=1), n_fails=n_fails, time_limit=time_limit), "C1_ls"),
			(iterate_monad(CBO_monad(local_search=VND, bottom_n=3), n_fails=n_fails, time_limit=time_limit), "C3_ls"),
			(iterate_monad(TBO_monad(local_search=identity, top_n=1), n_fails=n_fails, time_limit=time_limit), "T1"),
			(iterate_monad(TBO_monad(local_search=identity, top_n=3), n_fails=n_fails, time_limit=time_limit), "T3"),
			(iterate_monad(CBO_monad(local_search=identity, bottom_n=1), n_fails=n_fails, time_limit=time_limit), "C1"),
			(iterate_monad(CBO_monad(local_search=identity, bottom_n=3), n_fails=n_fails, time_limit=time_limit), "C3"),
		]

		results = Dict{String,Vector{Tuple{Int,Float64,Float64,String}}}()
		for (_alg, name) in algorithms
			results[name] = []
		end

	    for problem in problems
			println("")
	        println("testing problem #$(problem.index)")

			if verbose > 0
				p = "$(problem)"
			end

	        swarm = greedy_construct(problem, 30, repair_op=VSRO, local_search=VND, verbose=1, max_attempts=500_000)

			for (alg, name) in algorithms
				diversity = 0
				start_time = time_ns()
				if length(swarm) > 29
	            	newswarm, best_score = alg(deepcopy(swarm), problem)
					if length(swarm) > 4
						diversity = diversity_metric(newswarm)
					end
				elseif length(swarm) > 0
					best_score = find_best_score(swarm, problem)
					newswarm = swarm
				else
					best_score = 0
					newswarm = swarm
				end

				end_time = time_ns()
				elapsed_time = (end_time - start_time)/(10^9)
	            println("  $name found max score of $(best_score) in $(elapsed_time) seconds with $(diversity) diversity")

				#we want to record the whole swarm in order to compare behavior
				#of different heuristics. We also want to be able to find the
				#best score in python, so let's sort this
				#we also want to replace the swarm with a string of 0 and 1
				newswarm = [(reduce(*, [x ? "1" : "0" for x in s]), score_solution(s, problem)) for s in newswarm]
				sort!(newswarm, by=x->x[2])
	            push!(results[name], (best_score, elapsed_time, diversity, join(newswarm, ",")))
			end

			open(results_dir * "$(dataset).json", "w") do f
	       		write(f, JSON.json(results, 4))
	    	end

			if verbose > 0
				@assert p == "$(problem)"
			end

		end

		if verbose > 0
			@assert ps == "$(problems)"
		end
	end
end

main(verbose=1)
