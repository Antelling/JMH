"""http://www.growingscience.com/ijiec/Vol7/IJIEC_2015_32.pdf"""
function jaya(swarm::Swarm, problem::ProblemInstance; repair=false)
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
        new_solution = jaya_perturb(solution, best_solution, worst_solution)

        valid = false
        if repair && !is_valid(new_solution, problem)
            valid, new_solution = repair_op(new_solution, problem)
        end
        if (valid || is_valid(new_solution, problem)) && score_solution(new_solution, problem) > score_solution(solution, problem) && !(new_solution in swarm)
            swarm[i] = new_solution
        end
    end
    return (swarm, best_score)
end

"""apply the internal jaya transformation to a single solution in the swarm"""
function jaya_perturb(solution::BitList, best_solution::BitList, worst_solution::BitList)
    return [bit + rand([0, 1])*(best_solution[i]-bit) - rand([0, 1])*(worst_solution[i]-bit) > 0 for (i, bit) in enumerate(solution)]
end
