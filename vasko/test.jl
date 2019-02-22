include("parse_data.jl")
include("initial_pop.jl")
include("eval_solution.jl")
include("eval_problem.jl")
include("repair_op.jl")


problem = parse_file("data/mdmkp_ct1.txt")[6]
swarm = random_init(problem, 1, repair=true)
swarm = random_init(problem, 1, repair=false)

function bench()
    swarm = random_init(problem, 50, repair=false)
    swarm = random_init(problem, 50, repair=true)
end
