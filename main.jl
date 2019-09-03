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
const results_dir = "results/default_10s/"

function main(;verbose::Int=0)
	for dataset in 1:9
	    problems = parse_file(problems_dir * "mdmkp_ct$(dataset).txt")
		populations::Vector{Vector{BitList}} = JSON.parsefile(problems_dir * "$(dataset)_pop30_ls.json")
		if verbose > 0
			ps = "$(problems)"
		end
		n_fails = 50
		time_limit = 10



		algorithms = [
			(control_monad(), "control"),

			(iterate_monad(jaya_monad(top_n=1, bottom_n=1, perturb=jaya_perturb), time_limit=time_limit, n_fails=n_fails), "jaya"),
			(iterate_monad(jaya_monad(top_n=1, bottom_n=1, perturb=rao1_perturb), time_limit=time_limit, n_fails=n_fails), "rao1"),
			(iterate_monad(jaya_monad(top_n=1, bottom_n=1, perturb=rao2_perturb), time_limit=time_limit, n_fails=n_fails), "rao2"),
			(iterate_monad(TBO_monad(top_n=1), time_limit=time_limit, n_fails=n_fails), "TBO"),
			(iterate_monad(CBO_monad(bottom_n=1), n_fails=n_fails, time_limit=time_limit), "C1"),
			(iterate_monad(LBO_monad(), n_fails=n_fails, time_limit=time_limit), "LBO"),
			(iterate_monad(TLBO_monad(), n_fails=n_fails, time_limit=time_limit), "TLBO"),
			(iterate_monad(PGA_monad(n_parents=2, local_search=identity)), "PGA"),
			(iterate_monad(TGA_monad(local_search=identity)), "CGA"),
			(iterate_monad(IGA_monad(max_parents=2, local_search=identity)), "IGA"),


			(iterate_monad(jaya_monad(top_n=1, bottom_n=1, perturb=jaya_perturb, local_search=VND), time_limit=time_limit, n_fails=n_fails), "jaya_ls"),
			(iterate_monad(jaya_monad(top_n=1, bottom_n=1, perturb=rao1_perturb, local_search=VND), time_limit=time_limit, n_fails=n_fails), "rao1_ls"),
			(iterate_monad(jaya_monad(top_n=1, bottom_n=1, perturb=rao2_perturb, local_search=VND), time_limit=time_limit, n_fails=n_fails), "rao2_ls"),
			(iterate_monad(TBO_monad(local_search=VND, top_n=1), time_limit=time_limit, n_fails=n_fails), "TBO_ls"),
			(iterate_monad(CBO_monad(local_search=VND, bottom_n=1), n_fails=n_fails, time_limit=time_limit), "C1_ls"),
			(iterate_monad(LBO_monad(local_search=VND), n_fails=n_fails, time_limit=time_limit), "LBO_ls"),
			(iterate_monad(TLBO_monad(local_search=VND), n_fails=n_fails, time_limit=time_limit), "TLBO_ls"),
			(iterate_monad(PGA_monad(n_parents=2, local_search=VND)), "PGA_ls"),
			(iterate_monad(TGA_monad(local_search=VND)), "CGA_ls"),
			(iterate_monad(IGA_monad(max_parents=2, local_search=VND)), "IGA_ls"),
		]

		results = Dict{String,Vector{Tuple{Int,Float64,Float64,String}}}()
		try
			results = JSON.parsefile(results_dir * "$(dataset).json")
		catch SystemError
			for (_alg, name) in algorithms
				results[name] = []
			end
		end

	    for index in 1+length(results["control"]):90
			problem = problems[index]
			swarm = populations[index]
			println("")
	        println("testing problem #$(problem.index)")

			if verbose > 0
				p = "$(problem)"
			end

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

main()


"""
diversifying_seq = [
	LBO_monad(local_search=VND),
	GA_monad(n_parents=5, local_search=VND),
	TBO_monad(local_search=identity, top_n=30, v2=true),
	sloppy_jaya_monad(top_n=3, bottom_n=3, v2=true),
]

intensifying_seq = reverse(diversifying_seq)

oscillating_seq = [
	sloppy_jaya_monad(top_n=3, bottom_n=3, v2=true),
	GA_monad(n_parents=5, local_search=VND),
	TBO_monad(local_search=identity, top_n=30, v2=true),
	LBO_monad(local_search=VND),
]

input = [skate_monad([
	TLBO_monad(local_search=VND, top_n=30),
	GA_monad(n_parents=5, local_search=VND)],
	time_limit=20),
iterate_monad(
	IGA_monad(max_parents=5, local_search=VND),
	n_fails=100,
	time_limit=10)
]
capstone = (ordered_applicator_monad(input), "capstone")


algorithms = [(control_monad(), "control"),
	(LF_monad(), "LF"),
	(LS_monad(), "LS"),
	(VND_monad(), "VND"),

	(iterate_monad(TBO_monad(local_search=VND, top_n=1), n_fails=n_fails, time_limit=time_limit), "T1_ls"),
	(iterate_monad(TBO_monad(local_search=VND, top_n=3), n_fails=n_fails, time_limit=time_limit), "T3_ls"),
	(iterate_monad(TBO_monad(local_search=VND, top_n=7), n_fails=n_fails, time_limit=time_limit), "T7_ls"),
	(iterate_monad(TBO_monad(local_search=VND, top_n=15), n_fails=n_fails, time_limit=time_limit), "T15_ls"),
	(iterate_monad(TBO_monad(local_search=VND, top_n=30), n_fails=n_fails, time_limit=time_limit), "T30_ls"),

	(iterate_monad(TBO_monad(local_search=identity, top_n=1), n_fails=n_fails, time_limit=time_limit), "T1"),
	(iterate_monad(TBO_monad(local_search=identity, top_n=3), n_fails=n_fails, time_limit=time_limit), "T3"),
	(iterate_monad(TBO_monad(local_search=identity, top_n=7), n_fails=n_fails, time_limit=time_limit), "T7"),
	(iterate_monad(TBO_monad(local_search=identity, top_n=15), n_fails=n_fails, time_limit=time_limit), "T15"),
	(iterate_monad(TBO_monad(local_search=identity, top_n=30), n_fails=n_fails, time_limit=time_limit), "T30"),

	(iterate_monad(TBO_monad(local_search=VND, top_n=1, v2=true), n_fails=n_fails, time_limit=time_limit), "T1_ls_v2"),
	(iterate_monad(TBO_monad(local_search=VND, top_n=3, v2=true), n_fails=n_fails, time_limit=time_limit), "T3_ls_v2"),
	(iterate_monad(TBO_monad(local_search=VND, top_n=7, v2=true), n_fails=n_fails, time_limit=time_limit), "T7_ls_v2"),
	(iterate_monad(TBO_monad(local_search=VND, top_n=15, v2=true), n_fails=n_fails, time_limit=time_limit), "T15_ls_v2"),
	(iterate_monad(TBO_monad(local_search=VND, top_n=30, v2=true), n_fails=n_fails, time_limit=time_limit), "T30_ls_v2"),

	(iterate_monad(TBO_monad(local_search=identity, top_n=1, v2=true), n_fails=n_fails, time_limit=time_limit), "T1_v2"),
	(iterate_monad(TBO_monad(local_search=identity, top_n=3, v2=true), n_fails=n_fails, time_limit=time_limit), "T3_v2"),
	(iterate_monad(TBO_monad(local_search=identity, top_n=7, v2=true), n_fails=n_fails, time_limit=time_limit), "T7_v2"),
	(iterate_monad(TBO_monad(local_search=identity, top_n=15, v2=true), n_fails=n_fails, time_limit=time_limit), "T15_v2"),
	(iterate_monad(TBO_monad(local_search=identity, top_n=30, v2=true), n_fails=n_fails, time_limit=time_limit), "T30_v2"),


	(iterate_monad(CBO_monad(local_search=VND, bottom_n=1), n_fails=n_fails, time_limit=time_limit), "C1_ls"),
	(iterate_monad(CBO_monad(local_search=VND, bottom_n=3), n_fails=n_fails, time_limit=time_limit), "C3_ls"),
	(iterate_monad(CBO_monad(local_search=VND, bottom_n=7), n_fails=n_fails, time_limit=time_limit), "C7_ls"),
	(iterate_monad(CBO_monad(local_search=VND, bottom_n=15), n_fails=n_fails, time_limit=time_limit), "C15_ls"),
	(iterate_monad(CBO_monad(local_search=VND, bottom_n=30), n_fails=n_fails, time_limit=time_limit), "C30_ls"),

	(iterate_monad(CBO_monad(local_search=identity, bottom_n=1), n_fails=n_fails, time_limit=time_limit), "C1"),
	(iterate_monad(CBO_monad(local_search=identity, bottom_n=3), n_fails=n_fails, time_limit=time_limit), "C3"),
	(iterate_monad(CBO_monad(local_search=identity, bottom_n=7), n_fails=n_fails, time_limit=time_limit), "C7"),
	(iterate_monad(CBO_monad(local_search=identity, bottom_n=15), n_fails=n_fails, time_limit=time_limit), "C15"),
	(iterate_monad(CBO_monad(local_search=identity, bottom_n=30), n_fails=n_fails, time_limit=time_limit), "C30"),

	(iterate_monad(CBO_monad(local_search=VND, bottom_n=1, v2=true), n_fails=n_fails, time_limit=time_limit), "C1_ls_v2"),
	(iterate_monad(CBO_monad(local_search=VND, bottom_n=3, v2=true), n_fails=n_fails, time_limit=time_limit), "C3_ls_v2"),
	(iterate_monad(CBO_monad(local_search=VND, bottom_n=7, v2=true), n_fails=n_fails, time_limit=time_limit), "C7_ls_v2"),
	(iterate_monad(CBO_monad(local_search=VND, bottom_n=15, v2=true), n_fails=n_fails, time_limit=time_limit), "C15_ls_v2"),
	(iterate_monad(CBO_monad(local_search=VND, bottom_n=30, v2=true), n_fails=n_fails, time_limit=time_limit), "C30_ls_v2"),

	(iterate_monad(CBO_monad(local_search=identity, bottom_n=1, v2=true), n_fails=n_fails, time_limit=time_limit), "C1_v2"),
	(iterate_monad(CBO_monad(local_search=identity, bottom_n=3, v2=true), n_fails=n_fails, time_limit=time_limit), "C3_v2"),
	(iterate_monad(CBO_monad(local_search=identity, bottom_n=7, v2=true), n_fails=n_fails, time_limit=time_limit), "C7_v2"),
	(iterate_monad(CBO_monad(local_search=identity, bottom_n=15, v2=true), n_fails=n_fails, time_limit=time_limit), "C15_v2"),
	(iterate_monad(CBO_monad(local_search=identity, bottom_n=30, v2=true), n_fails=n_fails, time_limit=time_limit), "C30_v2"),


	(iterate_monad(LBO_monad(local_search=VND)), "LBO_ls"),
	(iterate_monad(LBO_monad(local_search=identity)), "LBO"),
	(iterate_monad(LBO_monad(local_search=VND, v2=true)), "LBO_ls_v2"),
	(iterate_monad(LBO_monad(local_search=identity, v2=true)), "LBO_v2"),


	(iterate_monad(TLBO_monad(local_search=identity)), "TLBO"),
	(iterate_monad(TLBO_monad(local_search=VND)), "TLBO_ls"),
	(iterate_monad(TLBO_monad(local_search=identity, v2=true)), "TLBO_v2"),
	(iterate_monad(TLBO_monad(local_search=VND, v2=true)), "TLBO_ls_v2"),


	(iterate_monad(GA_monad(n_parents=2, local_search=identity)), "GA2"),
	(iterate_monad(GA_monad(n_parents=5, local_search=identity)), "GA5"),
	(iterate_monad(GA_monad(n_parents=10, local_search=identity)), "GA10"),
	(iterate_monad(GA_monad(n_parents=20, local_search=identity)), "GA20"),
	(iterate_monad(GA_monad(n_parents=30, local_search=identity)), "GA30"),

	(iterate_monad(GA_monad(n_parents=2, local_search=VND)), "GA2_ls"),
	(iterate_monad(GA_monad(n_parents=5, local_search=VND)), "GA5_ls"),
	(iterate_monad(GA_monad(n_parents=10, local_search=VND)), "GA10_ls"),
	(iterate_monad(GA_monad(n_parents=20, local_search=VND)), "GA20_ls"),
	(iterate_monad(GA_monad(n_parents=30, local_search=VND)), "GA30_ls"),


	(iterate_monad(sloppy_jaya_monad(top_n=1, bottom_n=1)), "J1"),
	(iterate_monad(sloppy_jaya_monad(top_n=3, bottom_n=3)), "J3"),
	(iterate_monad(sloppy_jaya_monad(top_n=7, bottom_n=7)), "J7"),
	(iterate_monad(sloppy_jaya_monad(top_n=15, bottom_n=15)), "J15"),
	(iterate_monad(sloppy_jaya_monad(top_n=29, bottom_n=29)), "J30"),

	(iterate_monad(sloppy_jaya_monad(local_search=VND, top_n=1, bottom_n=1)), "J1_ls"),
	(iterate_monad(sloppy_jaya_monad(local_search=VND, top_n=3, bottom_n=3)), "J3_ls"),
	(iterate_monad(sloppy_jaya_monad(local_search=VND, top_n=7, bottom_n=7)), "J7_ls"),
	(iterate_monad(sloppy_jaya_monad(local_search=VND, top_n=15, bottom_n=15)), "J15_ls"),
	(iterate_monad(sloppy_jaya_monad(local_search=VND, top_n=29, bottom_n=29)), "J30_ls"),
	#
	(iterate_monad(sloppy_jaya_monad(top_n=1, bottom_n=1, v2=true)), "J1_v2"),
	(iterate_monad(sloppy_jaya_monad(top_n=3, bottom_n=3, v2=true)), "J3_v2"),
	(iterate_monad(sloppy_jaya_monad(top_n=7, bottom_n=7, v2=true)), "J7_v2"),
	(iterate_monad(sloppy_jaya_monad(top_n=15, bottom_n=15, v2=true)), "J15_v2"),
	(iterate_monad(sloppy_jaya_monad(top_n=29, bottom_n=29, v2=true)), "J30_v2"),

	(iterate_monad(sloppy_jaya_monad(local_search=VND, top_n=1, bottom_n=1, v2=true)), "J1_ls_v2"),
	(iterate_monad(sloppy_jaya_monad(local_search=VND, top_n=3, bottom_n=3, v2=true)), "J3_ls_v2"),
	(iterate_monad(sloppy_jaya_monad(local_search=VND, top_n=7, bottom_n=7, v2=true)), "J7_ls_v2"),
	(iterate_monad(sloppy_jaya_monad(local_search=VND, top_n=15, bottom_n=15, v2=true)), "J15_ls_v2"),
	(iterate_monad(sloppy_jaya_monad(local_search=VND, top_n=29, bottom_n=29, v2=true)), "J30_ls_v2"),
]
"""
