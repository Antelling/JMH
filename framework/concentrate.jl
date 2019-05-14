
"""remove columns that have no activated bits"""
function concentrate(swarm::Swarm, problem::ProblemInstance)::ProblemInstance
    problem = deepcopy(problem)

    mod = 0
    for i in 1:length(problem.objective)
        present = false
        for s in swarm
            if s[i]
                present = true
                break
            end
        end
        if !present
            deleteat!(problem.objective, i-mod)
            for j in 1:length(problem.upper_bounds)
                deleteat!(problem.upper_bounds[j][1], i-mod)
            end
            for j in 1:length(problem.lower_bounds)
                deleteat!(problem.lower_bounds[j][1], i-mod)
            end
            mod += 1
        end
    end
    return problem
end
