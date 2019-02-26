function find_best_score(swarm::Swarm, problem::ProblemInstance)
	results = [score_solution(s, problem) for s in swarm]
	return max(results...)
end

function iterate_alg(alg::Function, swarm::Swarm, problem::ProblemInstance; n_fails::Int=5, verbose=0, repair=false)
    failed_steps = 0
    prev_best_score = 0

    if verbose >= 1
        print("starting search with $(alg) algorithm")
    end

    while failed_steps < n_fails
        swarm, best_score = alg(swarm, problem, repair=repair)
		for s in swarm
	        @assert is_valid(s, problem)
	    end
		println(alg)
		println(best_score)
		println(find_best_score(swarm, problem))
		@assert best_score == find_best_score(swarm, problem)
        if best_score > prev_best_score
            if verbose >= 1
                println("")
                print("new best score: $(best_score)")
            end
            failed_steps = 0
            prev_best_score = best_score
        else
            if verbose >= 1
                print(" ...same result")
            end
            failed_steps += 1
        end
    end
    if verbose >= 1
        println("")
        println("$(n_fails) fails reached, exceeds n_fails, stopping")
    end

    for s in swarm
        @assert is_valid(s, problem)
    end
	@assert prev_best_score == find_best_score(swarm, problem)
    return (swarm, prev_best_score)
end

"""Randomly walk through all three algorithms. A complete cycle with no improvement is needed to stop."""
function walk_through_algs(algs::Vector{Function}, swarm::Swarm, problem::ProblemInstance; verbose::Int=0, repair=false)
    #we need to go through all three algs with no improvement in order to stop
    p = "$(problem)"

    prev_prev_alg = ""
    prev_alg = ""
    fails = 0
    best_score = 0
    while fails < 3
        alg = rand(algs)
        while "$(alg)" == prev_alg || "$(alg)" == prev_prev_alg
            alg = rand(algs)
        end
        swarm, current_score = iterate_alg(alg, swarm, problem, repair=repair, verbose=verbose)
        for s in swarm
            @assert is_valid(s, problem)
        end
		@assert current_score == find_best_score(swarm, problem)

        if current_score > best_score
            fails = 0
            best_score = current_score
            if verbose >= 1
                println("    improvement produced by $(alg), new score is $(current_score)")
            end
            #since this alg worked, the previous alg is back in the list of possible choices
            prev_alg = ""
        else
            fails += 1
            if verbose >= 2
                println("      $(alg) failed to improve")
            end
        end
        prev_prev_alg = prev_alg
        prev_alg = "$(alg)"
    end
    for s in swarm
        @assert is_valid(s, problem)
    end
	@assert best_score == find_best_score(swarm, problem)
    @assert p == "$(problem)"
    return (swarm, best_score)
end
