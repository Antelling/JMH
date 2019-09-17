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
const n_fails = 50
const time_limit = 10
const initial_pop_dir_suffix = "pop30_ls"
const results_dir = "results/rao_compare_$(time_limit)s_$(n_fails)f_$initial_pop_dir_suffix/"
run(`mkdir -p $(results_dir)`)

struct ResultSet
	score::Int
	time::Float64
	diversity::Float64
	bitlist::String
	improvement_points::ImprovementPoints
end

function main(;verbose::Int=0)

	algorithms = [
		(control_monad(), "control"),
		(VND_monad(), "VND"),
		(LF_monad(), "LF"),
		(iterate_monad(jaya_monad(perturb=jaya_perturb), time_limit=time_limit, n_fails=n_fails), "jaya"),
		(iterate_monad(jaya_monad(perturb=rao1_perturb), time_limit=time_limit, n_fails=n_fails), "rao1"),
		(iterate_monad(jaya_monad(perturb=jaya_perturb, local_search=VND), time_limit=time_limit, n_fails=n_fails), "jaya[VND]"),
		(iterate_monad(jaya_monad(perturb=rao1_perturb, local_search=VND), time_limit=time_limit, n_fails=n_fails), "rao1[VND]"),
		(iterate_monad(jaya_monad(perturb=jaya_perturb, local_search=local_flip), time_limit=time_limit, n_fails=n_fails), "jaya[LF]"),
		(iterate_monad(jaya_monad(perturb=rao1_perturb, local_search=local_flip), time_limit=time_limit, n_fails=n_fails), "rao1[LF]"),
		(skate_monad([jaya_monad(top_n=1, bottom_n=1, perturb=jaya_perturb), VND_monad()], time_limit=time_limit, n_fails=n_fails), "jaya&VND"),
		(skate_monad([jaya_monad(top_n=1, bottom_n=1, perturb=rao1_perturb), VND_monad()], time_limit=time_limit, n_fails=n_fails), "rao1&VND"),
		(skate_monad([jaya_monad(top_n=1, bottom_n=1, perturb=jaya_perturb), LF_monad()], time_limit=time_limit, n_fails=n_fails), "jaya&LF"),
		(skate_monad([jaya_monad(top_n=1, bottom_n=1, perturb=rao1_perturb), LF_monad()], time_limit=time_limit, n_fails=n_fails), "rao1&LF"),
		(ordered_applicator_monad([iterate_monad(jaya_monad(perturb=jaya_perturb), time_limit=time_limit, n_fails=n_fails), VND_monad()]), "jaya-->VND"),
		(ordered_applicator_monad([iterate_monad(jaya_monad(perturb=rao1_perturb), time_limit=time_limit, n_fails=n_fails), VND_monad()]), "rao1-->VND")
	]

	for dataset in 1:4
	    problems = parse_file(problems_dir * "mdmkp_ct$(dataset).txt")
		populations::Vector{Vector{BitList}} = JSON.parsefile(problems_dir * "$(dataset)_$(initial_pop_dir_suffix).json")

		results = Dict{String,Vector{ResultSet}}()
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
				improvement_points = ImprovementPoints()
				if length(swarm) > 2
	            	newswarm, best_score, improvement_points = alg(deepcopy(swarm), problem)
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

				result_set = ResultSet(best_score,elapsed_time,diversity,join(newswarm, ","),improvement_points)
	            push!(results[name], result_set)
			end

			if verbose > 0
				@assert p == "$(problem)"
			end
		end

		open(results_dir * "$(dataset).json", "w") do f
			write(f, JSON.json(results, 4))
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
