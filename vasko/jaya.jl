"""http://www.growingscience.com/ijiec/Vol7/IJIEC_2015_32.pdf"""
function jaya(swarm::Swarm, problem::ProblemInstance; repair::Bool=false, repair_op::Function)
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
        new_solution = jaya_perturb(swarm[i], best_solution, worst_solution)

        val = is_valid(new_solution, problem)
        if !val
            if repair
                val, new_solution = repair_op(new_solution, problem)
                if !val
                    continue
                end
            else
                continue
            end
        end
        s = score_solution(new_solution, problem)
        if s > score_solution(swarm[i], problem)
            swarm[i] = new_solution
            if s > best_score
                best_score = s
            end
        end
    end
    return (swarm, best_score)
end

"""apply the internal jaya transformation to a single solution in the swarm"""
function jaya_perturb(solution::BitList, best_solution::BitList, worst_solution::BitList)
    return [bit + rand([0, 1])*(best_solution[i]-bit) - rand([0, 1])*(worst_solution[i]-bit) > 0 for (i, bit) in enumerate(solution)]
end
