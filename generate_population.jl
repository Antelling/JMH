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

function compare()
	for dataset in 8:9
	    problems = parse_file(problems_dir * "mdmkp_ct$(dataset).txt")

		results = Vector{Vector{BitList}}()

		before_total = 0
		dec_total = 0
		greedy_construct(problems[1], 1, repair_op=VSRO, local_search=VND)
	    for problem in problems
			start_time = time()
			swarm = random_init(problem, 20, repair_op=VSRO)
			diff1 =  time() - start_time
			before_total += diff1
			problem = decimate_lowerbounds(problem)
			start_time2 = time()
			swarm = random_init(problem, 20, repair_op=VSRO)
			diff2 = time() - start_time2
			dec_total += diff2
			print(diff1, "  ", diff2)
			if diff1 > diff2
				println("")
			else
				println("🤔")
			end
		end
		#do we really have to go back in time
		println("     ", before_total, "  ", dec_total)
	end
end

function main()
	for dataset in 7:9
	    problems = parse_file(problems_dir * "mdmkp_ct$(dataset).txt")

		results = Vector{Vector{BitList}}()

	    for problem in problems[1+length(results):end]
			println(problem.index)
			problem = decimate_lowerbounds(problem)
			println("")
	        println("testing problem #$(problem.index)")

	        swarm = random_init(problem, 180, repair_op=VSRO, local_search=VND, max_time=10)

			push!(results, swarm)
		end
		open(results_dir * "$(dataset)_pop180_ls_decimated.json", "w") do f
			write(f, JSON.json(results))
		end
	end
end
main()
