"""Vasko's Simple Repair Op"""
 function VSRO(solution::BitList, problem::ProblemInstance)::Tuple{Bool,BitList}
    solution = deepcopy(solution)
    #we can assume that because this was called the solution is not feasible
    #we need to get the values for the objective and every bound
    objective_value = sum(problem.objective .* solution)
    upper_values::Vector{Int} = [sum(solution .* bound[1]) for bound in problem.upper_bounds]
    lower_values::Vector{Int} = [sum(solution .* bound[1]) for bound in problem.lower_bounds]

    fails = 0
    max_fails = 2
    while fails < max_fails
        least_infeasible::Int = typemax(Int)
        least_inf_bit_i = 0

        best_feasible_objective = 0
        best_feasible_bit_index = 0
        feasible = false

        for i in 1:length(solution) #loop over every bit in the solution
            infeasibility_total::Int = 0

            #loop over upper bounds
            for j in 1:length(problem.upper_bounds)
                new_bound_total::Int = upper_values[j]
                if solution[i]
                    #if the bit was turned on, turn it off, so subtract the bounds value for this bit
                    new_bound_total -= problem.upper_bounds[j][1][i]
                else
                    new_bound_total += problem.upper_bounds[j][1][i]
                end
                if new_bound_total > problem.upper_bounds[j][2]
                    infeasibility_total += new_bound_total - problem.upper_bounds[j][2]
                end
            end

            #loop over lower bounds
            for j in 1:length(problem.lower_bounds)
                new_bound_total::Int = lower_values[j]
                if solution[i]
                    new_bound_total -= problem.lower_bounds[j][1][i]
                else
                    new_bound_total += problem.lower_bounds[j][1][i]
                end
                if new_bound_total < problem.lower_bounds[j][2]
                    infeasibility_total += problem.upper_bounds[j][2] - new_bound_total
                end
            end

            if infeasibility_total < least_infeasible
                least_infeasible = infeasibility_total
                least_inf_bit_i = i
            end

            if infeasibility_total == 0
                current_objective = objective_value
                if solution[i]
                    current_objective -= problem.objective[i]
                else
                    current_objective += problem.objective[i]
                end
                if current_objective > best_feasible_objective || !feasible
                    best_feasible_objective = current_objective
                    best_feasible_bit_index = i
                end
                feasible = true
            end
        end
        if feasible
            solution[best_feasible_bit_index] = !solution[best_feasible_bit_index]
            return (true, solution)
        end
        solution[least_inf_bit_i] = !solution[least_inf_bit_i]

        fails += 1
    end
    return (false, solution)
end

"""Least Squares Repair Op
I don't feel like doing VSRO properly so let's cheat and pretend it's a linear thing
"""
function LSRO(solution::BitList, problem::ProblemInstance)
    #we can assume that because this function was called, the solution is not valid
    valid = false
    #now we loop until we are valid, or 5 times
    i = 0
    while !valid && i < 5
        i += 1
        #we need to calculate the importance of each constraint
        #importance is error^2
        #and if the constraint is satisfied its -(error^2)
        weights::Vector{Int} = []
        for (bounds, comparison) in [(problem.upper_bounds, <=), (problem.lower_bounds, >=)]
            for bound in bounds
                score = sum(solution .* bound[1])
                lse = (score - bound[2])^2
                if comparison(score, bound[2])
                    lse *= -1
                end
                push!(weights, lse)
            end
        end

        println(weights)

    end
end


const repair_op = VSRO
