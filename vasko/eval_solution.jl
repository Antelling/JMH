include("structs.jl")

"""returns the solution .* the objective function"""
function score_solution(solution::BitList, problem::ProblemInstance)
    return sum(problem.objective .* solution)
end

"""determines if the solution violates any constraints"""
function is_valid(solution::BitList, problem::ProblemInstance)
    valid = true

    for upper_bound in problem.upper_bounds
        if sum(upper_bound[1] .* solution) > upper_bound[2]
            valid = false
        end
    end

    for lower_bound in problem.lower_bounds
        if sum(lower_bound[1] .* solution) > lower_bound[2]
            valid = false
        end
    end

    return valid
end

"""get inclusive (min, max) tuple of the range sum(BitList) may return"""
function get_solution_range(problem::ProblemInstance)
    max_value = min([get_max_on(bound[1], bound[2]) for bound in problem.upper_bounds]...)
    min_value = max([get_min_on(bound[1], bound[2]) for bound in problem.lower_bounds]...)
    return (min_value, max_value)
end

"""find maximum amount of variables that can be turned on
before the upper bound is violated"""
function get_max_on(weights::Vector{Int}, max_value::Int)
    sort!(weights) #we sort so the smallest comes first
    i = 0
    total = 0
    for weight in weights
        total += weight
        if total > max_value
            break
        end
        i += 1
    end
    return i
end

"""find minimum amount of variables that can be turned on while still
satisfying lower bound"""
function get_min_on(weights::Vector{Int}, min_value::Int)
    sort!(weights, by=i->-i) #sort descending
    i = 0
    total = 0
    for weight in weights
        if total >= min_value
            break
        end
        total += weight
        i += 1
    end
    return i
end
