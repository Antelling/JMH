"""http://www.growingscience.com/ijiec/Vol7/IJIEC_2015_32.pdf"""
function jaya(swarm::Swarm, problem::ProblemInstance)
    n_dimensions = length(problem.objective)

    best_solution::BitList = []
    worst_solution::BitList = []
    best_score = 0
    worst_score = Inf
    for solution in swarm
        current_score = score_solution(solution, problem)
        if current_score > best_score
            best_score = current_score
            best_solution = solution
        end
        if current_score < worst_score
            worst_score = current_score
            worst_solution = solution
        end
    end

    for i in 1:length(swarm)
        solution = swarm[i]
        new_solution = copy(solution)
        for j in 1:n_dimensions
            #FIXME: why is abs() here
            new_bit = solution[j] + rand([0, 1])*(best_solution[j]-abs(solution[j])) - rand([0, 1])*(worst_solution[j]-abs(solution[j]))

            #this formula produces ranges from -1 to 2, which will upset our Bool function
            #so we use this value check to convert to Bool
            new_solution[j] = new_bit > 0
        end
        old_score = score_solution(solution, problem)
        new_score = score_solution(new_solution, problem)
        if new_score > old_score && is_valid(new_solution, problem)
            swarm[i] = new_solution
        end
    end
    return (swarm, best_score)
end
