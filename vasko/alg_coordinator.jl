function iterate_alg(alg::Function, swarm::Swarm, problem::ProblemInstance, n_fails::Int=5; verbose=0)
    failed_steps = 0
    prev_best_score = 0

    if verbose >= 1
        print("starting search with $(alg) algorithm")
    end

    while failed_steps < n_fails
        swarm, best_score = alg(swarm, problem)
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
    return swarm
end