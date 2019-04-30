using Random: randperm

"""Find the best performing solution in the swarm.
This is only called when verbose > 0 in a function, as part of @asserts.
Otherwise the best_score is kept track of within algorithms."""
function find_best_score(swarm::Swarm, problem::ProblemInstance)
	results = [score_solution(s, problem) for s in swarm]
	return max(results...)
end

"""returns a configured iteration instance"""
function iterate_monad(alg::Function; verbose::Int=0, n_fails::Int=5)
    return function iter_monad_internal(swarm::Swarm, problem::ProblemInstance)
        return iterate_alg(alg, swarm, problem, verbose=verbose, n_fails=5)
    end
end

"""Will apply the passed algorithm function to the swarm over and over until
it fails n_fails times in a row."""
function iterate_alg(alg::Function, swarm::Swarm, problem::ProblemInstance; n_fails::Int=5, verbose=0)

    failed_steps = 0
    prev_best_score = 0

    if verbose >= 2
        print("starting search with $(alg) algorithm")
		assert_no_duplicates(swarm)
    end

    while failed_steps < n_fails
		assert_no_duplicates(swarm)
        swarm, best_score = alg(swarm, problem, verbose=verbose-1)
		if verbose > 0 #use verbose as a debug flag
			for s in swarm
		        @assert is_valid(s, problem)
		    end
			@assert best_score == find_best_score(swarm, problem)
			assert_no_duplicates(swarm)
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

"""returns a configured triplicate instance"""
function triplicate_monad(algs::Vector{Function}; verbose::Int=0)
	return function(swarm::Swarm, problem::ProblemInstance)
        return walk_through_algs(algs, swarm, problem, verbose=verbose)
    end
end

function total_score(pop::Swarm, problem::ProblemInstance)
	return sum([score_solution(sol, problem) for sol in pop])
end

"""Randomly walk through the passed list of algorithms.
A complete cycle with no improvement is needed to stop."""
function walk_through_algs(algs::Vector{Function}, swarm::Swarm, problem::ProblemInstance;
			verbose::Int=0)
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

        swarm, current_score = iterate_alg(alg, swarm, problem, verbose=verbose-1)
		#current_score is the score of the best solution in the swarm
		#but we want to look at the swarm as a whole
		#since a single solution in the swarm will never get worse, we can just:
		current_score = total_score(swarm, problem)
		if verbose > 0
	        for s in swarm
	            @assert is_valid(s, problem)
	        end
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
	    @assert p == "$(problem)"
	end
    return (swarm, find_best_score(swarm, problem))
end
