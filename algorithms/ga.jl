using StatsBase: sample

function GA_monad(; repair_op::Function=VSRO, n_parents=2, n_generations=200, local_search::Function=identity)
    return function GA_monad_internal(swarm::Swarm, problem::ProblemInstance; verbose::Int=0)
        return GA(swarm, problem, repair_op=repair_op, n_parents=n_parents,
                n_generations=n_generations, verbose=verbose,
                local_search=local_search)
    end
end

function GA(swarm::Swarm, problem::ProblemInstance;
        repair_op::Function=VSRO,
        local_search::Function=identity,
        verbose::Int=0,
        n_parents::Int=2, n_generations::Int=200)
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
            val, new_solution = repair_op(new_solution, problem)
            if !val
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

        new_solution = local_search(new_solution, problem)
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


function manhattan_distance(a::BitList, b::BitList)
    return sum(abs.(a .- b))
end

function IGA_monad(; repair_op::Function=VSRO, max_parents::Int=2, attempts::Int=200, local_search::Function=identity)
    return function IGA_monad_internal(swarm::Swarm, problem::ProblemInstance; verbose::Int=0)
        return IGA(swarm, problem, repair_op=repair_op, max_parents=max_parents,
                attempts=attempts, verbose=verbose,
                local_search=local_search)
    end
end

"""Intensifying Genetic Algorithm
randomly select parent then choose closest n solutions as other parents"""
function IGA(swarm::Swarm, problem::ProblemInstance;
        repair_op::Function=VSRO,
        local_search::Function=identity,
        verbose::Int=0,
        max_parents::Int=2, attempts::Int=200)
    n_dimensions = length(swarm[1])
    n_solutions = length(swarm)

    best_score = 0

    for n in 1:attempts
        n_parents = max(2, rand(1:max_parents))
        first_parent = rand(1:n_solutions)
        distances = Vector{Tuple{Int64,Float64}}()
        for (i, sol) in enumerate(swarm)
            push!(distances, tuple(i, manhattan_distance(swarm[first_parent], swarm[i])))
        end
        sort!(distances, by=x->x[2])
        parents = vcat([first_parent], [x[1] for x in distances[2:n_parents-1]])
        averages::Vector{Float64} = zeros(n_dimensions)
        for p in parents
            averages .+= swarm[p]
        end
        averages ./= n_parents

        new_solution::BitList = [rand() < percent for percent in averages]
        val = is_valid(new_solution, problem)
        if !val
            val, new_solution = repair_op(new_solution, problem)
            if !val
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

        new_solution = local_search(new_solution, problem)
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


function CGA_monad(; repair_op::Function=VSRO, attempts::Int=200, local_search::Function=identity)
    return function CGA_monad_internal(swarm::Swarm, problem::ProblemInstance; verbose::Int=0)
        return IGA(swarm, problem, repair_op=repair_op,
                attempts=attempts, verbose=verbose,
                local_search=local_search)
    end
end

"""Classic Genetic Algorithm
"""
function CGA(swarm::Swarm, problem::ProblemInstance;
        repair_op::Function=VSRO,
        local_search::Function=identity,
        verbose::Int=0,
        attempts::Int=200)
    n_dimensions = length(swarm[1])
    n_solutions = length(swarm)

    best_score = 0

    for n in 1:attempts
        #choose parents
        a = rand(1:n_solutions)
        b = rand(1:n_solutions)
        while a == b
            b = rand(1:n_solutions)
        end

        #generate new solution
        stopping_point = rand(2:n_dimensions-1)
        new_solution = vcat(swarm[a][1:stopping_point], swarm[b][stopping_point+1, end])

        val = is_valid(new_solution, problem)
        if !val
            val, new_solution = repair_op(new_solution, problem)
            if !val
                continue
            end
        end
        new_solution = local_search(new_solution, problem)

        #replace parents
        a_score = score_solution(swarm[a], problem)
        b_score = score_solution(swarm[b], problem)
        new_score = score_solution(new_solution, problem)
        if a_score < b_score && new_score > a_score
            swarm[a] = new_solution
        elseif b_score < a_score && new_score > b_score
            swarm[b] = new_solution
        end
    end
    return (swarm, find_best_score(swarm, problem))
end
