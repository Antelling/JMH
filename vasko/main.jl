include("parse_data.jl")
problems = parse_file("data/mdmkp_ct1.txt")

include("initial_pop.jl")
include("eval_solution.jl")
include("eval_problem.jl")
include("repair_op.jl")

include("alg_coordinator.jl")
include("jaya.jl")
include("tlbo.jl")

for problem in problems[1:10]
    swarm = random_init(problem, 100, repair=false)
    swarm, best_score = walk_through_algs([jaya, TBO, LBO], swarm, problem, verbose=2)
    println(best_score)
end