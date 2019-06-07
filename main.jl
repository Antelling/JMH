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
const results_dir = "results/gigantic_search/"

function main(;verbose::Int=0)
	for dataset in [4, 5, 6, 8, 9]
	    problems = parse_file(problems_dir * "mdmkp_ct$(dataset).txt")
		if verbose > 0
			ps = "$(problems)"
		end
		n_fails = 25
		time_limit = 10
		algorithms = [(control_monad(), "control"),
				(iterate_monad(LS_monad(), n_fails=2, time_limit=time_limit), "LS"),
				(iterate_monad(LF_monad(), n_fails=2, time_limit=time_limit), "LF"),
				(iterate_monad(VND_monad(), n_fails=2, time_limit=time_limit), "VND"),
				(iterate_monad(GA_monad(local_search=VND, n_parents=2), n_fails=n_fails, time_limit=time_limit), "GA2_ls"),
				(iterate_monad(GA_monad(local_search=VND, n_parents=5), n_fails=n_fails, time_limit=time_limit), "GA5_ls"),
				(iterate_monad(GA_monad(local_search=VND, n_parents=10), n_fails=n_fails, time_limit=time_limit), "GA10_ls"),
				(iterate_monad(GA_monad(local_search=VND, n_parents=20), n_fails=n_fails, time_limit=time_limit), "GA20_ls"),
				(iterate_monad(GA_monad(local_search=VND, n_parents=30), n_fails=n_fails, time_limit=time_limit), "GA30_ls"),
				(iterate_monad(GA_monad(n_parents=2), n_fails=n_fails, time_limit=time_limit), "GA2"),
				(iterate_monad(GA_monad(n_parents=5), n_fails=n_fails, time_limit=time_limit), "GA5"),
				(iterate_monad(GA_monad(n_parents=10), n_fails=n_fails, time_limit=time_limit), "GA10"),
				(iterate_monad(GA_monad(n_parents=20), n_fails=n_fails, time_limit=time_limit), "GA20"),
				(iterate_monad(GA_monad(n_parents=30), n_fails=n_fails, time_limit=time_limit), "GA30"),
				(iterate_monad(TBO_monad(local_search=VND, top_n=1), n_fails=n_fails, time_limit=time_limit), "T1_ls"),
				(iterate_monad(TBO_monad(local_search=VND, top_n=5), n_fails=n_fails, time_limit=time_limit), "T5_ls"),
				(iterate_monad(TBO_monad(local_search=VND, top_n=10), n_fails=n_fails, time_limit=time_limit), "T10_ls"),
				(iterate_monad(TBO_monad(local_search=VND, top_n=20), n_fails=n_fails, time_limit=time_limit), "T20_ls"),
				(iterate_monad(TBO_monad(local_search=VND, top_n=30), n_fails=n_fails, time_limit=time_limit), "T30_ls"),
				(iterate_monad(TBO_monad(top_n=1), n_fails=n_fails, time_limit=time_limit), "T1"),
				(iterate_monad(TBO_monad(top_n=5), n_fails=n_fails, time_limit=time_limit), "T5"),
				(iterate_monad(TBO_monad(top_n=10), n_fails=n_fails, time_limit=time_limit), "T10"),
				(iterate_monad(TBO_monad(top_n=20), n_fails=n_fails, time_limit=time_limit), "T20"),
				(iterate_monad(TBO_monad(top_n=30), n_fails=n_fails, time_limit=time_limit), "T30"),
				(iterate_monad(jaya_monad(local_search=VND), n_fails=n_fails, time_limit=time_limit), "jaya_ls"),
				(iterate_monad(jaya_monad(), n_fails=n_fails, time_limit=time_limit), "jaya"),
				(iterate_monad(TLBO_monad(local_search=VND, top_n=1), n_fails=n_fails, time_limit=time_limit), "TL1_ls"),
				(iterate_monad(TLBO_monad(local_search=VND, top_n=5), n_fails=n_fails, time_limit=time_limit), "TL5_ls"),
				(iterate_monad(TLBO_monad(local_search=VND, top_n=10), n_fails=n_fails, time_limit=time_limit), "TL10_ls"),
				(iterate_monad(TLBO_monad(local_search=VND, top_n=20), n_fails=n_fails, time_limit=time_limit), "TL20_ls"),
				(iterate_monad(TLBO_monad(local_search=VND, top_n=30), n_fails=n_fails, time_limit=time_limit), "TL30_ls"),
				(iterate_monad(TLBO_monad(top_n=1), n_fails=n_fails, time_limit=time_limit), "TL1"),
				(iterate_monad(TLBO_monad(top_n=5), n_fails=n_fails, time_limit=time_limit), "TL5"),
				(iterate_monad(TLBO_monad(top_n=10), n_fails=n_fails, time_limit=time_limit), "TL10"),
				(iterate_monad(TLBO_monad(top_n=20), n_fails=n_fails, time_limit=time_limit), "TL20"),
				(iterate_monad(TLBO_monad(top_n=30), n_fails=n_fails, time_limit=time_limit), "TL30"),
				(iterate_monad(LBO_monad(local_search=VND), n_fails=n_fails, time_limit=time_limit), "LBO_ls"),
				(iterate_monad(LBO_monad(), n_fails=n_fails, time_limit=time_limit), "LBO"),
				(iterate_monad(G2JG4TL_monad(local_search=VND), n_fails=n_fails, time_limit=time_limit), "G2JG4TL_ls"),
				(iterate_monad(G2JG4TL_monad(), n_fails=n_fails, time_limit=time_limit), "G2JG4TL")]

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

	        swarm = greedy_construct(problem, 30, repair_op=VSRO, local_search=identity, verbose=1, max_attempts=500_000)

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
				else
					best_score = 0
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
