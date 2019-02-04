include("parse_data.jl")
problem = parse_file("data/mdmkp_ct8.txt")[6]

include("initial_pop.jl")
include("eval_solution.jl")
include("eval_problem.jl")
include("repair_op.jl")
swarm = random_init(problem, 100, verbose=2, repair=false)
println("")

include("alg_coordinator.jl")
include("jaya.jl")
include("tlbo.jl")

for alg in [jaya, LBO, TBO]
    println("testing single algorithm $(alg)...")
    _, best_score = iterate_alg(alg, copy(swarm), problem)
    println("produced score $(best_score)")
    println("")
end

println("testing all three algorithms...")
swarm, best_score = walk_through_algs([jaya, TBO, LBO], copy(swarm), problem, verbose=2, repair=false)
println("produced score $(best_score)")
