"""returns a configured jaya instance"""
function jaya_monad(; repair_op::Function=VSRO, local_search::Function=identity, v2::Bool=false)
    return function jaya_monad_internal(swarm::Swarm, problem::ProblemInstance; verbose::Int=0)
        return jaya(swarm, problem, repair_op=repair_op, local_search=local_search, v2=v2)
    end
end

"""implementation of http://www.growingscience.com/ijiec/Vol7/IJIEC_2015_32.pdf
But any continous range was made into a sample of discrete integers on that range."""
function jaya(swarm::Swarm, problem::ProblemInstance; repair_op::Function=VSRO,
            local_search::Function=identity, verbose::Int=0, v2::Bool=false)
    n_dimensions = length(problem.objective)

    best_solution::BitList = []
    worst_solution::BitList = []
    best_score = 0
    worst_score = Inf
    for solution in swarm
        current_score = score_solution(solution, problem)
        if current_score > best_score
            best_score = current_score
            best_solution = solution
        end
        if current_score < worst_score
            worst_score = current_score
            worst_solution = solution
        end
    end

    if verbose > 3
        println("best and worse solutions found")
    end

    for i in 1:length(swarm)
        if v2
            new_solution = v2_jaya_perturb(swarm[i], best_solution, worst_solution)
        else
            new_solution = jaya_perturb(swarm[i], best_solution, worst_solution)
        end

        val = is_valid(new_solution, problem)
        if !val
            val, new_solution = repair_op(new_solution, problem)
            if !val
                continue
            end
        end
        new_solution = local_search(new_solution, problem)
        s = score_solution(new_solution, problem)
        if s > score_solution(swarm[i], problem) && !(new_solution in swarm)
            swarm[i] = new_solution
            if s > best_score
                best_score = s
            end
        end
    end
    return (swarm, best_score)
end

function sloppy_jaya_monad(; repair_op::Function=VSRO, local_search::Function=identity,
        v2::Bool=false, top_n::Int=1, bottom_n::Int=1)
    return function jaya_monad_internal(swarm::Swarm, problem::ProblemInstance; verbose::Int=0)
        return sloppy_jaya(swarm, problem, repair_op=repair_op,
                local_search=local_search, v2=v2, top_n=top_n, bottom_n=bottom_n)
    end
end

function sloppy_jaya(swarm::Swarm, problem::ProblemInstance; repair_op::Function=VSRO,
            local_search::Function=identity, verbose::Int=0, v2::Bool=false, top_n::Int=1, bottom_n::Int=1)
    n_dimensions = length(problem.objective)

    best_score = 0
    new_swarm = [(s, score_solution(s, problem)) for s in swarm]
    sort!(new_swarm, by=x -> x[2])
    best_solution = rand(new_swarm[1:top_n])[1]
    worst_solution = rand(new_swarm[end-bottom_n:end])[1]

    for i in 1:length(swarm)
        if v2
            new_solution = v2_jaya_perturb(swarm[i], best_solution, worst_solution)
        else
            new_solution = jaya_perturb(swarm[i], best_solution, worst_solution)
        end

        val = is_valid(new_solution, problem)
        if !val
            val, new_solution = repair_op(new_solution, problem)
            if !val
                continue
            end
        end
        new_solution = local_search(new_solution, problem)
        s = score_solution(new_solution, problem)
        if s > score_solution(swarm[i], problem) && !(new_solution in swarm)
            swarm[i] = new_solution
            if s > best_score
                best_score = s
            end
        end
    end
    return (swarm, best_score)
end

"""apply the internal jaya transformation to a single solution in the swarm"""
function jaya_perturb(solution::BitList, best_solution::BitList, worst_solution::BitList)
    return [bit + rand([0, 1])*(best_solution[i]-bit) - rand([0, 1])*(worst_solution[i]-bit) > 0 for (i, bit) in enumerate(solution)]
end

function v2_jaya_perturb(solution::BitList, best_solution::BitList, worst_solution::BitList)
    best_vector_scale = rand()
    worst_vector_scale = rand()
    return [bit + (rand()<best_vector_scale)*(best_solution[i]-bit) - (rand()<worst_vector_scale)*(worst_solution[i]-bit) > 0 for (i, bit) in enumerate(solution)]
end
