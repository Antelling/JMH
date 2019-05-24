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
const results_dir = "results/"

function main(;verbose::Int=0)
	for dataset in 5:7
	    problems = parse_file(problems_dir * "mdmkp_ct$(dataset).txt")
		if verbose > 0
			ps = "$(problems)"
		end
		n_fails = 25
		algorithms = [
				(control_monad(), "control"),
				# (ordered_walk_monad(
				# 	[TBO_monad(), LBO_monad(), GA_monad(), jaya_monad()], n_fails=n_fails), "TLGJ_pogo"),
				(ordered_walk_monad(
					[
						GA_monad(local_search=VND),
						jaya_monad(local_search=VND),
						GA_monad(local_search=VND, n_parents=4),
						TBO_monad(local_search=VND),
						LBO_monad(local_search=VND)
					], n_fails=n_fails), "G2JG4TL_VND-watershed_pogo"),
				# (iterate_monad(TLGJ_monad(), n_fails=n_fails), "TLGJ_skate"),
				(iterate_monad(G2JG4TL_monad(local_search=VND), n_fails=n_fails), "G2JG4TL_VND-watershed_skate"),
				# (ordered_walk_monad(
				# 	[LBO_monad(), jaya_monad(), TBO_monad()], n_fails=n_fails), "ljt"),
				# (iterate_monad(jaya_monad(local_search=VND), n_fails=n_fails), "jaya_ls"),
				# (iterate_monad(TBO_monad(local_search=VND), n_fails=n_fails), "TBO_ls"),
				# (iterate_monad(LBO_monad(local_search=VND), n_fails=n_fails), "LBO_ls"),
				# (iterate_monad(TLBO_monad(local_search=VND), n_fails=n_fails), "TLBO_ls"),
				# (iterate_monad(GA_monad(local_search=VND), n_fails=n_fails), "GA2_ls"),
				# (iterate_monad(jaya_monad(), n_fails=n_fails), "jaya"),
				# (iterate_monad(TBO_monad(), n_fails=n_fails), "TBO"),
				# (iterate_monad(LBO_monad(), n_fails=n_fails), "LBO"),
				# (iterate_monad(TLBO_monad(), n_fails=n_fails), "TLBO"),
				# (iterate_monad(GA_monad(), n_fails=n_fails), "GA2"),
				# (iterate_monad(GA_monad(n_parents=3), n_fails=n_fails), "GA3"),
				# (iterate_monad(GA_monad(n_parents=4), n_fails=n_fails), "GA_4_parents"),
				# (iterate_monad(GA_monad(n_parents=5), n_fails=n_fails), "GA_5_parents"),
				# (triplicate_monad(
				# 	[jaya_monad(),
				# 	TBO_monad(),
				# 	LBO_monad()], n_fails=n_fails), "triplicate"),
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
				if length(swarm) > 2
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
				best_bitstring = reduce(*, [x ? "1" : "0" for x in find_best_solution(swarm, problem)])
	            push!(results[name], (best_score, elapsed_time, diversity, best_bitstring))
			end

			open(results_dir * "$(dataset)_dread_churn_3__$(today()).json", "w") do f
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
