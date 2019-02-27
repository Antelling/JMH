using Random: randperm

"""Find the best performing solution in the swarm.
This is only called when verbose > 0 in a function, as part of @asserts.
Otherwise the best_score is kept track of within algorithms."""
function find_best_score(swarm::Swarm, problem::ProblemInstance)
	results = [score_solution(s, problem) for s in swarm]
	return max(results...)
end

"""Will apply the passed algorithm function to the swarm over and over until
it fails n_fails times in a row. The params repair::Bool and repair_op::Function
control if repair_op is applied to infeasible solutions."""
function iterate_alg(alg::Function, swarm::Swarm, problem::ProblemInstance;
			n_fails::Int=5, verbose=0, repair::Bool=false, repair_op::Function)

    failed_steps = 0
    prev_best_score = 0

    if verbose >= 2
        print("starting search with $(alg) algorithm")
    end

    while failed_steps < n_fails
        swarm, best_score = alg(swarm, problem, repair=repair, repair_op=repair_op)
		if verbose > 0 #use verbose as a debug flag
			for s in swarm
		        @assert is_valid(s, problem)
		    end
			@assert best_score == find_best_score(swarm, problem)
		end
        if best_score > prev_best_score
            if verbose >= 3
                println("")
                print("new best score: $(best_score)")
            end
            failed_steps = 0
            prev_best_score = best_score
        else
            if verbose >= 4
                print(" ...same result")
            end
            failed_steps += 1
        end
    end
    if verbose >= 2
        println("")
        println("$(n_fails) fails reached, exceeds n_fails, stopping")
    end

	if verbose > 0
	    for s in swarm
	        @assert is_valid(s, problem)
	    end
		@assert prev_best_score == find_best_score(swarm, problem)
	end
    return (swarm, prev_best_score)
end

"""Randomly walk through the passed list of algorithms.
A complete cycle with no improvement is needed to stop."""
function walk_through_algs(algs::Vector{Function}, swarm::Swarm, problem::ProblemInstance;
			verbose::Int=0, repair::Bool=false,repair_op::Function)
	if verbose > 0
    	p = "$(problem)" #this is used as a deepcopy that == still works on
		#it's slow and hacky but only called while debugging so who cares
		#we're making sure that the problem isn't being mutated
	end

	n_algs = length(algs)
	best_score = 0

    failed_algs::Vector{Function} = []
    fails = 0
    while fails < n_algs
        alg = rand(algs)
        for i in randperm(n_algs)
			alg = algs[i]
			if !(alg in failed_algs)
				#there should always be at least one alg not in failed algs
				#since the loop would have ended otherwise
				break
			end
		end

        swarm, current_score = iterate_alg(alg, swarm, problem, repair=repair, repair_op=repair_op, verbose=verbose)
		if verbose > 0
	        for s in swarm
	            @assert is_valid(s, problem)
	        end
			@assert current_score == find_best_score(swarm, problem)
			@assert !(alg in failed_algs)
		end

        if current_score > best_score
            best_score = current_score
            if verbose >= 1
                println("    improvement produced by $(alg), new score is $(current_score)")
            end
            #since this alg worked, we clear out failed_algs
            failed_algs = [] #this isn't type unstable, it remembers
			fails = 0
        else
            fails += 1
            if verbose >= 2
                println("      $(alg) failed to improve")
            end
        end
        push!(failed_algs, alg)
        fails += 1 #notice that this runs even if the alg was successful
		#this is because we don't want to just run it again on the same swarm
    end
	if verbose > 0
	    for s in swarm
	        @assert is_valid(s, problem)
	    end
		@assert best_score == find_best_score(swarm, problem)
	    @assert p == "$(problem)"
	end
    return (swarm, best_score)
end
