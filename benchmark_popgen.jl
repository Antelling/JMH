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

const problems_dir = "beasley_mdmkp_datasets/"
const results_dir = problems_dir

struct problem_results
	best_solution::String
	best_score::Int
	worst_solution::String
	worst_score::Int
	time::Float64
	diversity::Float64
	n_solutions::Int
end


function main(;verbose::Int=0)
	for dataset in [1, 1, 7, 8, 9]
	    problems = parse_file(problems_dir * "mdmkp_ct$(dataset).txt")

		plain_results = Vector{problem_results}()
		repair_results = Vector{problem_results}()
		vnd_repair_results = Vector{problem_results}()

	    for problem in problems
			println("")
	        println("testing problem #$(problem.index)")

			for (repair, search, results) in [
					(identity_repair, identity, plain_results),
					(VSRO, identity, repair_results),
					(VSRO, VND, vnd_repair_results)]

				start_time = time_ns()
		        swarm = greedy_construct(problem, 30, repair_op=repair, local_search=search, max_time=10, max_attempts = 10000000)
				end_time = time_ns()
				elapsed_time = (end_time - start_time)/(10^9)

				n_solutions = length(swarm)
				best_solution = n_solutions > 0 ? find_best_solution(swarm, problem) : []
				best_score = n_solutions > 0 ? score_solution(best_solution, problem) : 0.0
				worst_solution = n_solutions > 0 ? find_worst_solution(swarm, problem) : []
				worst_score = n_solutions > 0 ? score_solution(worst_solution, problem) : 0.0

				diversity = n_solutions > 3 ? diversity_metric(swarm) : 0.0

				best_solution = reduce(*, [x ? "1" : "0" for x in best_solution])
				worst_solution = reduce(*, [x ? "1" : "0" for x in worst_solution])

				push!(results, problem_results(best_solution, best_score, worst_solution, worst_score, elapsed_time, diversity, n_solutions))
			end
		end

		results = Dict("plain_results"=>plain_results,
			"repair_results"=>repair_results,
			"vnd_repair_results"=>vnd_repair_results)
		open("results/benchmark_popgen/$(dataset).json", "w") do f
			write(f, JSON.json(results, 4))
		end
	end
end

main()
