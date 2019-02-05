include("parse_data.jl")
const problems = parse_file("data/mdmkp_ct1.txt")

include("initial_pop.jl")
include("eval_solution.jl")
include("eval_problem.jl")
include("repair_op.jl")

include("alg_coordinator.jl")
include("jaya.jl")
include("tlbo.jl")

function get_best(swarm::Swarm, problem::ProblemInstance)
    best_sol::BitList = []
    best_score = 0
    for solution in swarm
        s = score_solution(solution, problem)
        if s > best_score
            best_score = s
            best_sol = solution
        end
    end
    return (best_score, best_sol)
end

for problem in problems[1:6:90]
    swarm = random_init(deepcopy(problem), 100, repair=false)
    swarm, best_score = walk_through_algs([jaya, TBO, LBO], swarm, problem, verbose=0)

    best_score, best_sol = get_best(swarm, problem)
    println(best_score)
    #println(is_valid(best_sol, problem))
end