function random_walk(swarm::Swarm, problem::ProblemInstance)
    [single_walk(s, problem, .01, 30) for s in swarm]

    best_score = max([score_solution(s, problem) for s in swarm]...)
    return (swarm, best_score)
end

function single_walk(solution::BitList, problem::ProblemInstance, flip_chance::Float64, n_tries::Int)
    prev_score = score_solution(solution, problem)
    for i in 1:n_tries
        new_solution = copy(solution)
        for j in 1:length(solution)
            if rand()<flip_chance
                new_solution[j] = !new_solution[j]
            end
            new_score = score_solution(new_solution, problem)
            if new_score > prev_score & is_valid(new_solution, problem)
                prev_score = new_score
                solution = new_solution
            end
        end
    end
end