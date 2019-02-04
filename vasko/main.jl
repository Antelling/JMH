include("parse_data.jl")
problem = parse_file("data/mdmkp_ct1.txt")[6]

include("initial_pop.jl")
swarm = random_initialize(problem, 30, verbose=2)

include("alg_coordinator.jl")
include("jaya.jl")
iterate_alg(jaya, copy(swarm), problem, verbose=1)

include("tlbo.jl")
iterate_alg(LBO, copy(swarm), problem, verbose=1)

include("random_walk.jl")
iterate_alg(random_walk, copy(swarm), problem, verbose=1)
