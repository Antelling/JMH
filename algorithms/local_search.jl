
function LS_monad()
    return function LS_monad_internal(swarm::Swarm, problem::ProblemInstance; verbose::Int=0)
        return swarm_local_swap(swarm, problem)
    end
end


function swarm_local_swap(swarm::Swarm, problem::ProblemInstance; verbose::Int=0)
    for i in 1:length(swarm)
        new_sol = local_swap(swarm[i], problem)
        if !(new_sol in swarm)
            swarm[i] = new_sol
        end
    end
    improvement_points = ImprovementPoints()
    best_score = find_best_score(swarm, problem)
    push!(improvement_points, (1, best_score))
    return (swarm, best_score, improvement_points)
end

function local_swap(sol::BitList, problem::ProblemInstance; verbose::Int=0)
    prev_sol = sol
    new_sol = _individual_swap(sol, problem)
    while prev_sol != new_sol
        prev_sol = deepcopy(new_sol)
        new_sol = _individual_swap(new_sol, problem)
    end
    return new_sol
end

function _individual_swap(sol::BitList, problem::ProblemInstance)
    objective_value = sum(problem.objective .* sol)
    upper_values::Vector{Int} = [sum(sol .* bound[1]) for bound in problem.upper_bounds]
    lower_values::Vector{Int} = [sum(sol .* bound[1]) for bound in problem.lower_bounds]

    best_found_objective = objective_value
    best_found_solution::BitList = deepcopy(sol)
    for i in 1:length(sol)
        if sol[i]
            for j in 1:length(sol)
                if !sol[j]
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
                            changed_value = lower_values[p] - problem.lower_bounds[p][1][i] + problem.lower_bounds[p][1][j]
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

function _slow_individual_swap(sol::BitList, problem::ProblemInstance; only_best::Bool=true)
    objective_value = sum(problem.objective .* sol)
    upper_values::Vector{Int} = [sum(sol .* bound[1]) for bound in problem.upper_bounds]
    lower_values::Vector{Int} = [sum(sol .* bound[1]) for bound in problem.lower_bounds]

    best_found_objective = objective_value
    best_found_solution::BitList = deepcopy(sol)

    discovered_feasible::Vector{Tuple{BitList,Int}} = []
    starting_value = score_solution(sol, problem)
    push!(discovered_feasible, tuple(sol, starting_value))
    for i in 1:length(sol)
        if sol[i] #find something in the sack
            for j in 1:length(sol)
                if !sol[j] #find an item out of the sack
                    valid = true
                    #check feasibility of this swap for every upper bound
                    for p in 1:length(problem.upper_bounds)
                        changed_value = upper_values[p] - problem.upper_bounds[p][1][i] + problem.upper_bounds[p][1][j]
                        if changed_value > problem.upper_bounds[p][2]
                            valid = false
                            break
                        end
                    end
                    if valid
                        #check feasibility of this swap for every lower bound
                        for p in 1:length(problem.lower_bounds)
                            changed_value = lower_values[p] - problem.lower_bounds[p][1][i] + problem.lower_bounds[p][1][j]
                            if changed_value < problem.lower_bounds[p][2]
                                valid = false
                                break
                            end
                        end
                    end
                    if valid
                        new_objective_value = objective_value - problem.objective[i] + problem.objective[j]
                        if new_objective_value >= starting_value
                            best_found_solution = deepcopy(sol) #copy the solution and apply the transform
                            best_found_solution[i] = false
                            best_found_solution[j] = true
                            push!(discovered_feasible, tuple(best_found_solution, new_objective_value))
                        end
                    end
                end
            end
        end
    end
    sort!(discovered_feasible, by=i->i[1])
    if only_best
        return discovered_feasible[end][1]
    else
        return [a[1] for a in discovered_feasible]
    end
end

function LF_monad()
    return function LF_monad_internal(swarm::Swarm, problem::ProblemInstance; verbose::Int=0)
        return swarm_local_flip(swarm, problem)
    end
end


function swarm_local_flip(swarm::Swarm, problem::ProblemInstance; verbose::Int=0)
    for i in 1:length(swarm)
        new_sol = local_flip(swarm[i], problem)
        if !(new_sol in swarm)
            swarm[i] = new_sol
        end
    end
    improvement_points = ImprovementPoints()
    best_score = find_best_score(swarm, problem)
    push!(improvement_points, (1, best_score))
    return (swarm, best_score, improvement_points)
end

function local_flip(sol::BitList, problem::ProblemInstance; verbose::Int=0)
    prev_sol = sol
    new_sol = _individual_flip(sol, problem)
    while prev_sol != new_sol
        prev_sol = deepcopy(new_sol)
        new_sol = _individual_flip(new_sol, problem)
    end
    return new_sol
end

function _individual_flip(sol::BitList, problem::ProblemInstance)
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


function swarm_VND(swarm::Swarm, problem::ProblemInstance; verbose::Int=0)
    for i in 1:length(swarm)
        new_sol = VND(swarm[i], problem)
        if !(new_sol in swarm)
            swarm[i] = new_sol
        end
    end

    improvement_points = ImprovementPoints()
    best_score = find_best_score(swarm, problem)
    push!(improvement_points, (1, best_score))
    return (swarm, best_score, improvement_points)
end

function VND(sol::BitList, problem::ProblemInstance; verbose::Int=0)
    prev_sol = sol
    new_sol = _individual_flip(sol, problem)
    new_sol = _individual_swap(new_sol, problem)
    while prev_sol != new_sol
        prev_sol = deepcopy(new_sol)
        new_sol = _individual_flip(new_sol, problem)
        new_sol = _individual_swap(new_sol, problem)
    end
    return new_sol
end

function VND_monad()
    return function VND_monad_internal(swarm::Swarm, problem::ProblemInstance; verbose::Int=0)
        return swarm_VND(swarm, problem)
    end
end


function BF_VND(swarm::Swarm, problem::ProblemInstance; n_branches::Int=3)
    searched_solutions = Set{BitList}()
    discovered_solutions = Set{BitList}()

    for sol in swarm
        push!(discovered_solutions, sol)
    end

    while length(discovered_solutions) > 0
        new_discovered_solutions = Set{BitList}()
        for sol in discovered_solutions
            push!(searched_solutions, sol)
            feasible_neighbors = _individual_swap(sol, problem, only_best=false)[1:min(end, n_branches)]
            # print("$(length(feasible_neighbors)) ")
            for n in feasible_neighbors
                if !in(n, searched_solutions)
                    push!(new_discovered_solutions, n)
                end
            end
        end
        discovered_solutions = new_discovered_solutions
        println(length(discovered_solutions))
    end

    best_solutions = Vector{Tuple{BitList,Int}}()
    for sol in searched_solutions
        push!(best_solutions, tuple(sol, score_solution(sol, problem)))
    end
    sort!(best_solutions, by=i->i[2])
    best_score = best_solutions[1][2]
    limited = best_solutions[1:length(swarm)]
    return ([l[1] for l in limited], best_score)
end

function BF_VND_monad(;n_branches::Int=3)
    return function BF_VND_monad_internal(swarm::Swarm, problem::ProblemInstance; verbose::Int=0)
        return BF_VND(swarm, problem, n_branches=n_branches)
    end
end
