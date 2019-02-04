function repair_op(solution::BitList, problem::ProblemInstance)
    valid_solutions = Set{BitList}()
    fails = 0
    while fails == 0
        fails = 1
        improved_solution::BitList = []
        best_improvement = 0
        infeasibility = violates_upper(solution, problem) + violates_lower(solution, problem)
        for i in 1:length(solution)
            solution[i] = !solution[i]
            new_infeasibility = violates_upper(solution, problem) + violates_lower(solution, problem)
            reduction = infeasibility - new_infeasibility
            if reduction > best_improvement
                best_improvement = reduction
                improved_solution = copy(solution)
                fails = 0

                if new_infeasibility == 0
                    push!(valid_solutions, copy(solution))
                end
            end
            solution[i] = !solution[i]
        end
        solution = improved_solution
        if length(valid_solutions) > 0
            best_solution::BitList = []
            best_score = 0
            for vs in valid_solutions
                s = score_solution(vs, problem)
                if s > best_score
                    best_solution = vs
                    best_score = s
                end
            end
            return (true, best_solution)
        end
    end
    return (false, solution)
end