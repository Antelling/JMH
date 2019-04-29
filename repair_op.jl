"""Vasko's Simple Repair Op"""
function VSRO(sol::BitList, problem::ProblemInstance)::Tuple{Bool,BitList}
    solution = deepcopy(sol)

    #we can assume that because this was called the solution is not feasible
    #we need to get the values for the objective and every bound
    objective_value = sum(problem.objective .* solution)
    upper_values::Vector{Int} = [sum(solution .* bound[1]) for bound in problem.upper_bounds]
    lower_values::Vector{Int} = [sum(solution .* bound[1]) for bound in problem.lower_bounds]

    prev_infeasibility::Int64 = typemax(Int64)
    cur_infeasibility::Int64 = typemax(Int64)-1
    while cur_infeasibility < prev_infeasibility
        prev_infeasibility = cur_infeasibility

        least_infeasible::Int = typemax(Int)
        least_inf_bit_i::Int = 0

        best_feasible_objective::Int = 0
        best_feasible_bit_index::Int = 0
        feasible::Bool = false

        for (i, bit) in enumerate(solution) #loop over every bit in the solution
            infeasibility_total::Int = 0

            #loop over upper bounds
            for (j, upper_bound) in enumerate(problem.upper_bounds)
                new_bound_total::Int = upper_values[j]
                if bit
                    #if the bit was turned on, turn it off, so subtract the bounds value for this bit
                    new_bound_total -= upper_bound[1][i]
                else
                    new_bound_total += upper_bound[1][i]
                end
                if new_bound_total > upper_bound[2]
                    infeasibility_total += new_bound_total - upper_bound[2]
                end
            end

            #loop over lower bounds
            for (j, lower_bound) in enumerate(problem.lower_bounds)
                new_bound_total::Int = lower_values[j]
                if bit
                    new_bound_total -= lower_bound[1][i]
                else
                    new_bound_total += lower_bound[1][i]
                end
                if new_bound_total < lower_bound[2]
                    infeasibility_total += lower_bound[2] - new_bound_total
                end
            end

            if infeasibility_total < least_infeasible
                least_infeasible = infeasibility_total
                least_inf_bit_i = i
            end

            if infeasibility_total == 0
                current_objective = objective_value
                if bit
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
            @assert is_valid(solution, problem) == true
            return (true, solution)
        end

        #we didn't find a valid solution, so change to the least infeasible
        #solution found and run through again
        solution[least_inf_bit_i] = !solution[least_inf_bit_i]
        #we also need to update the objective upper and lower values
        plus_or_minus = solution[least_inf_bit_i] ? 1 : -1
        objective_value += problem.objective[least_inf_bit_i] * plus_or_minus
        for i in 1:length(problem.upper_bounds)
            upper_values[i] += problem.upper_bounds[i][1][least_inf_bit_i] * plus_or_minus
        end
        for i in 1:length(problem.lower_bounds)
            lower_values[i] += problem.lower_bounds[i][1][least_inf_bit_i] * plus_or_minus
        end

        cur_infeasibility = violates_lower(solution, problem) + violates_upper(solution, problem)
    end

    return (false, solution)
end
