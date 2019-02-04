include("parse_data.jl")
problem = parse_file("data/mdmkp_ct8.txt")[6]

include("initial_pop.jl")
swarm = random_initialize(problem, 100, verbose=2)
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
swarm, best_score = walk_through_algs([jaya, TBO, LBO], copy(swarm), problem, verbose=2)
println("produced score $(best_score)")
