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
const results_dir = problems_dir

function main(;verbose::Int=0)
	for dataset in 1:9
	    problems = parse_file(problems_dir * "mdmkp_ct$(dataset).txt")

		results = Vector{Vector{BitList}}()

	    for problem in problems[1+length(results):end]
			println("")
	        println("testing problem #$(problem.index)")

	        swarm = greedy_construct(problem, 180, repair_op=VSRO, local_search=VND, verbose=1, max_time=10, max_attempts=1000000000)

			push!(results, swarm)
		end
		open(results_dir * "$(dataset)_pop180_ls.json", "w") do f
			write(f, JSON.json(results))
		end
	end
end

main()
