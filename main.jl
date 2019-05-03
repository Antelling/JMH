include("parse_data.jl")

include("initial_pop.jl")
include("eval_solution.jl")
include("eval_problem.jl")
include("eval_swarm.jl")
include("repair_op.jl")

include("alg_coordinator.jl")
include("jaya.jl")
include("tlbo.jl")

import JSON
using Random


function main(;verbose::Int=0)
	for dataset in [8]
	    problems = parse_file("data/mdmkp_ct$(dataset).txt")
		if verbose > 0
			ps = "$(problems)"
		end
	    results = Dict{String,Vector{Tuple{Int,Float64}}}(
			"jaya_repair"=>[],
			"TBO_prob_repair"=>[],
			"TBO_med_repair"=>[],
			"LBO_repair"=>[],
			"triplicate_prob_repair"=>[],
			"triplicate_med_repair"=>[],
			"jaya_no_repair"=>[],
			"TBO_prob_no_repair"=>[],
			"TBO_med_no_repair"=>[],
			"LBO_no_repair"=>[],
			"triplicate_prob_no_repair"=>[],
			"triplicate_med_no_repair"=>[]
		)


	    for problem in [problems[30]] #Random.shuffle(problems)
			println("")
	        println("testing problem #$(problem.index)")

			if verbose > 0
				p = "$(problem)"
			end

	        swarm = dimensional_focus(problem, 30, repair=true, repair_op=VSRO, verbose=1, max_attempts=100_000)
			assert_no_duplicates(swarm)
			println("  got swarm")

			for (alg, name) in [
					#(iterate_monad(jaya_monad(repair=false)), "jaya_no_repair"),
					#(iterate_monad(jaya_monad(repair=true, repair_op=VSRO)), "jaya_repair"),
					#(iterate_monad(TBO_monad(repair=false, prob=false)), "TBO_med_no_repair"),
					#(iterate_monad(TBO_monad(repair=false, prob=true)), "TBO_prob_no_repair"),
					#(iterate_monad(TBO_monad(repair=true, prob=false, repair_op=VSRO)), "TBO_med_repair"),
					#(iterate_monad(TBO_monad(repair=true, prob=true, repair_op=VSRO)), "TBO_prob_repair"),
					#(iterate_monad(LBO_monad(repair=false)), "LBO_no_repair"),
					#(iterate_monad(LBO_monad(repair=true, repair_op=VSRO)), "LBO_repair"),
					#(triplicate_monad(
				#		[jaya_monad(repair=false),
			#			TBO_monad(repair=false, prob=false),
			#			LBO_monad(repair=false)]), "triplicate_med_no_repair"),
			#		(triplicate_monad(
			#			[jaya_monad(repair=false),
			#			TBO_monad(repair=false, prob=true),
			#			LBO_monad(repair=false)]), "triplicate_prob_no_repair"),
			#		(triplicate_monad(
			#			[jaya_monad(repair=true, repair_op=VSRO),
			#			TBO_monad(repair=true, repair_op=VSRO, prob=false),
			#			LBO_monad(repair=true, repair_op=VSRO)]), "triplicate_med_repair"),
					(triplicate_monad(
						[jaya_monad(repair=true, repair_op=VSRO),
						TBO_monad(repair=true, repair_op=VSRO, prob=true),
						LBO_monad(repair=true, repair_op=VSRO)]), "triplicate_prob_repair"),]

				start_time = time_ns()
				if length(swarm) > 2
	            	_, best_score = alg(swarm, problem)
				elseif length(swarm) > 0
					best_score = find_best_score(swarm, problem)
				else
					best_score = 0
				end

				end_time = time_ns()
				elapsed_time = (end_time - start_time)/(10^9)
	            println("  $name found max score of $(best_score) in $(elapsed_time) seconds")
				println(find_best_solution(swarm, problem))
	            push!(results[name], (best_score, elapsed_time))
			end

			#open("results/bbbbb_$(dataset).json", "w") do f
	       # 	write(f, JSON.json(results, 4))
	    #	end

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
