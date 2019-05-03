function assert_no_duplicates(swarm::Swarm)
    for (i::Int, a::BitList) in enumerate(swarm)
        for (j::Int, b::BitList) in enumerate(swarm)
            @assert (i == j || a != b)
        end
    end
end

function find_best_solution(swarm::Swarm, problem::ProblemInstance)
    best_score::Int = 0
    best_solution::BitList = []
    for solution in swarm
        if score_solution(solution, problem) > best_score
            best_score = score_solution(solution, problem)
            best_solution = solution
        end
    end
    return best_solution
end
