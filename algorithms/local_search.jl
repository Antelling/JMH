
function LS_monad()
    return function LS_monad_internal(swarm::Swarm, problem::ProblemInstance; verbose::Int=0)
        return local_swap(swarm, problem)
    end
end


function local_swap(swarm::Swarm, problem::ProblemInstance; verbose::Int=0)
    for i in 1:length(swarm)
        new_sol = individual_swap(swarm[i], problem)
        if !(new_sol in swarm)
            swarm[i] = new_sol
        end
    end
    return (swarm, find_best_score(swarm, problem))
end

function individual_swap(sol::BitList, problem::ProblemInstance)
    objective_value = sum(problem.objective .* sol)
    upper_values::Vector{Int} = [sum(sol .* bound[1]) for bound in problem.upper_bounds]
    lower_values::Vector{Int} = [sum(sol .* bound[1]) for bound in problem.lower_bounds]

    best_found_objective = objective_value
    best_found_solution::BitList = sol
    for i in 1:length(sol)
        if sol[i]
            for j in 1:length(sol)
                if !sol[j]
                    if i == j break end
                    valid = true
                    for p in 1:length(problem.upper_bounds)
                        changed_value = upper_values[p] - problem.upper_bounds[p][1][i] + problem.upper_bounds[p][1][j]
                        if changed_value > problem.upper_bounds[p][2]
                            valid = false
                            break
                        end
                    end
                    if valid
                        for p in 1:length(problem.lower_bounds)
                            changed_value = lower_values[p] - problem.lower_bounds[p][1][i] + problem.upper_bounds[p][1][j]
                            if changed_value < problem.lower_bounds[p][2]
                                valid = false
                                break
                            end
                        end
                    end
                    if valid
                        new_objective_value = objective_value - problem.objective[i] + problem.objective[j]
                        if new_objective_value > best_found_objective
                            best_found_objective = new_objective_value
                            best_found_solution = deepcopy(sol)
                            best_found_solution[i] = false
                            best_found_solution[j] = true
                        end
                    end
                end
            end
        end
    end
    return best_found_solution
end

function LF_monad()
    return function LF_monad_internal(swarm::Swarm, problem::ProblemInstance; verbose::Int=0)
        return local_flip(swarm, problem)
    end
end


function local_flip(swarm::Swarm, problem::ProblemInstance; verbose::Int=0)
    for i in 1:length(swarm)
        new_sol = individual_flip(swarm[i], problem)
        if !(new_sol in swarm)
            swarm[i] = new_sol
        end
    end
    return (swarm, find_best_score(swarm, problem))
end

function individual_flip(sol::BitList, problem::ProblemInstance)
    objective_value = sum(problem.objective .* sol)
    upper_values::Vector{Int} = [sum(sol .* bound[1]) for bound in problem.upper_bounds]
    lower_values::Vector{Int} = [sum(sol .* bound[1]) for bound in problem.lower_bounds]

    best_found_objective = objective_value
    best_found_solution::BitList = sol
    for i in 1:length(sol)
        valid = true

        on_or_off = sol[i] ? -1 : 1
        for p in 1:length(problem.upper_bounds)
            changed_value = upper_values[p] + (problem.upper_bounds[p][1][i] * on_or_off)
            if changed_value > problem.upper_bounds[p][2]
                valid = false
                break
            end
        end

        if valid
            for p in 1:length(problem.lower_bounds)
                changed_value = lower_values[p] + (problem.lower_bounds[p][1][i] * on_or_off)
                if changed_value < problem.lower_bounds[p][2]
                    valid = false
                    break
                end
            end
        end

        if valid
            new_objective_value = objective_value + (problem.objective[i] * on_or_off)
            if new_objective_value > best_found_objective
                best_found_objective = new_objective_value
                best_found_solution = deepcopy(sol)
                best_found_solution[i] = !best_found_solution[i]
            end
        end
    end
    return best_found_solution
end


function VND(swarm::Swarm, problem::ProblemInstance; verbose::Int=0)
    for i in 1:length(swarm)
        new_sol = individual_swap(swarm[i], problem)
        new_sol = individual_flip(new_sol, problem)
        if !(new_sol in swarm)
            swarm[i] = new_sol
        end
    end
    return (swarm, find_best_score(swarm, problem))
end

function VND_monad()
    return function VND_monad_internal(swarm::Swarm, problem::ProblemInstance; verbose::Int=0)
        return VND(swarm, problem)
    end
end
