"""returns the solution .* the objective function"""
function score_solution(solution::BitList, problem::ProblemInstance)
    return sum(problem.objective .* solution)
end

"""determines if the solution violates any constraints"""
function is_valid(solution::BitList, problem::ProblemInstance)
    for upper_bound in problem.upper_bounds
        if sum(upper_bound[1] .* solution) > upper_bound[2]
            return false
        end
    end
    for lower_bound in problem.lower_bounds
        if sum(lower_bound[1] .* solution) < lower_bound[2]
            return false
        end
    end
    return true
end

"""returns a numerical value describing how far over the upper bound a solution is. Returns 0 if
it is a valid solution"""
function violates_upper(solution::BitList, problem::ProblemInstance)
    violation = 0
    for upper_bound in problem.upper_bounds
        total = sum(upper_bound[1] .* solution)
        if total > upper_bound[2]
            valid = false
            violation += total - upper_bound[2]
        end
    end
    return violation
end

"""returns a numerical value describing how far under the lower bound a solution is. Returns 0 if
it is a valid solution"""
function violates_lower(solution::BitList, problem::ProblemInstance)
    violation = 0
    for lower_bound in problem.lower_bounds
        total = sum(lower_bound[1] .* solution)
        if total < lower_bound[2]
            violation += lower_bound[2] - total
        end
    end
    return violation
end
