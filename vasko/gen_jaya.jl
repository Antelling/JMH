#generalized jaya function


"""returns a configured jaya instance"""
function gen_jaya_monad(; repair::Bool=false, repair_op::Function=Pass,
        feasibility_check::Function=is_valid,
        score::Function=score_solution)

    return function(swarm::Swarm, problem::ProblemInstance)
        return gen_jaya(swarm, problem, repair=repair, repair_op=repair_op, feasibility_check=feasibility_check, score=score)
    end
end

"""implementation of http://www.growingscience.com/ijiec/Vol7/IJIEC_2015_32.pdf
But any continous range was made into a sample of discrete integers on that range."""
function gen_jaya(swarm::Swarm, problem::ProblemInstance;
        repair::Bool=false, repair_op::Function=Pass,
        feasibility_check::Function=is_valid,
        score::Function=score_solution)

    n_dimensions = length(problem.objective)

    best_solution::BitList = []
    worst_solution::BitList = []
    best_score = -Inf
    worst_score = Inf
    for solution in swarm
        current_score = score(solution, problem)
        if current_score > best_score
            best_score = current_score
            best_solution = solution
        end
        if current_score < worst_score
            worst_score = current_score
            worst_solution = solution
        end
    end

    for i in 1:length(swarm)
        new_solution = gen_jaya_perturb(swarm[i], best_solution, worst_solution)

        val = feasibility_check(new_solution, problem)
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
        
        if in(swarm, new_solution)
            #we don't want duplicates
            continue
        end

        s = score(new_solution, problem)
        if s > score(swarm[i], problem) #FIXME: cache this somewhere
            swarm[i] = new_solution
            if s > best_score
                best_score = s
            end
        end
    end
    return (swarm, best_score)
end

"""apply the internal jaya transformation to a single solution in the swarm"""
function gen_jaya_perturb(solution::BitList, best_solution::BitList, worst_solution::BitList)
    return [bit + rand([0, 1])*(best_solution[i]-bit) - rand([0, 1])*(worst_solution[i]-bit) > 0 for (i, bit) in enumerate(solution)]
end
