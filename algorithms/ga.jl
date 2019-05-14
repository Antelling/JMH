using StatsBase: sample

"""returns a configured jaya instance"""
function GA_monad(; repair::Bool=true, repair_op::Function=VSRO, n_parents=2, n_generations=200)
    return function GA_monad_internal(swarm::Swarm, problem::ProblemInstance; verbose::Int=0)
        return GA(swarm, problem, repair=repair, repair_op=repair_op, n_parents=n_parents, n_generations=n_generations, verbose=verbose)
    end
end

"""genetic algorithm"""
function GA(swarm::Swarm, problem::ProblemInstance;
        repair::Bool=true, repair_op::Function=VSRO,
        verbose::Int=0,
        n_parents=2, n_generations=n_generations)
    n_dimensions = length(swarm[1])
    n_solutions = length(swarm)

    best_score = 0

    for n in 1:n_generations
        parents = sample(1:n_solutions, n_parents, replace=false)
        averages::Vector{Float64} = zeros(n_dimensions)
        for p in parents
            averages .+= swarm[p]
        end
        averages ./= n_parents

        new_solution::BitList = [rand() < percent for percent in averages]
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

        lowest_score = -1
        lowest_p = 1
        for p in parents
            score = score_solution(swarm[p], problem)
            if lowest_score == -1
                lowest_score = score
                lowest_p = p
            elseif score < lowest_score
                lowest_score = score
                lowest_p = p
            end
        end

        s = score_solution(new_solution, problem)
        if s > lowest_score && !(new_solution in swarm)
            swarm[lowest_p] = new_solution
            if s > best_score
                best_score = s
            end
        end
    end
    return (swarm, best_score)
end
