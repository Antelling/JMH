"""get inclusive (min, max) tuple of the range sum(BitList) may return"""
function get_solution_range(p::ProblemInstance)
    problem = deepcopy(p) #FIXME: this is hacky and slow but it doesn't matter much right now
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
