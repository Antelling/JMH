function jaya_monad(; repair_op::Function=VSRO, local_search::Function=identity,
        v2::Bool=false, top_n::Int=1, bottom_n::Int=1, perturb=jaya_perturb)
    return function jaya_monad_internal(swarm::Swarm, problem::ProblemInstance; verbose::Int=0)
        return jaya(swarm, problem, repair_op=repair_op,
                local_search=local_search, top_n=top_n, bottom_n=bottom_n,
                perturb=perturb)
    end
end

"""implementation of http://www.growingscience.com/ijiec/Vol7/IJIEC_2015_32.pdf
But any continous range was made into a sample of discrete integers on that range.
Implicit parameters were made discrete. """
function jaya(swarm::Swarm, problem::ProblemInstance; repair_op::Function=VSRO,
            local_search::Function=identity, verbose::Int=0, perturb::Function, top_n::Int=1, bottom_n::Int=1)
    n_dimensions = length(problem.objective)

    best_score = 0
    new_swarm = [(s, score_solution(s, problem)) for s in swarm]
    sort!(new_swarm, by=x -> x[2])
    best_solution = rand(new_swarm[1:top_n])[1]
    worst_solution = rand(new_swarm[end-bottom_n:end])[1]
    random_solution = rand(new_swarm)[1]

    for i in 1:length(swarm)
        new_solution = perturb(swarm[i], best_solution, worst_solution, random_solution, problem)

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
    improvement_points = ImprovementPoints()
    push!(improvement_points, (1, best_score))
    return (swarm, best_score, improvement_points)
end


function jaya_perturb(solution::BitList, best_solution::BitList, worst_solution::BitList, random_solution::BitList, problem::ProblemInstance)
    return [bit + rand([0, 1])*(best_solution[i]-bit) - rand([0, 1])*(worst_solution[i]-bit) > 0 for (i, bit) in enumerate(solution)]
end

function v2_jaya_perturb(solution::BitList, best_solution::BitList, worst_solution::BitList, random_solution::BitList, problem::ProblemInstance)
    best_vector_scale = rand()
    worst_vector_scale = rand()
    return [bit + (rand()<best_vector_scale)*(best_solution[i]-bit) - (rand()<worst_vector_scale)*(worst_solution[i]-bit) > 0 for (i, bit) in enumerate(solution)]
end

function rao1_perturb(solution::BitList, best_solution::BitList, worst_solution::BitList, random_solution::BitList, problem::ProblemInstance)
    return [bit + rand([0, 1])*(best_solution[i]-worst_solution[1]) > 0 for (i, bit) in enumerate(solution)]
end

function rao2_perturb(solution::BitList, best_solution::BitList, worst_solution::BitList, random_solution::BitList, problem::ProblemInstance)
    sol_score = score_solution(solution, problem)
    rand_sol_score = score_solution(random_solution, problem)
    if sol_score > rand_sol_score
        better_solution = solution
        worse_solution = random_solution
    else
        better_solution = random_solution
        worse_solution = solution
    end
    return [bit + rand([0, 1])*(best_solution[i]-worst_solution[i]) + rand([0, 1])*(better_solution[i]-worse_solution[i]) > 0 for (i, bit) in enumerate(solution)]
end
