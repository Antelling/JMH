include("parse_data.jl")
problems = parse_file("data/mdmkp_ct1.txt")

include("initial_pop.jl")
include("eval_solution.jl")
include("eval_problem.jl")
include("repair_op.jl")

include("alg_coordinator.jl")
include("jaya.jl")
include("tlbo.jl")

total = ""
for problem in problems[1:6]
    global total *= "\nProblem---"
    global total *= "\nobjective: $(problem.objective[1:3])...$(problem.objective[end-2:end])"
    for bound in problem.upper_bounds
        global total *= "\nupper bound: $(bound[1][1:3])...$(bound[1][end-2:end]) <= $(bound[2])"
    end
    for bound in problem.lower_bounds
        global total *= "\nlower bound: $(bound[1][1:3])...$(bound[1][end-2:end]) >= $(bound[2])"
    end
end
open("test.txt", "w") do f
    write(f, total)
end

for problem in problems[1:10]
    swarm = random_init(problem, 100, repair=false)
    swarm, best_score = walk_through_algs([jaya, TBO, LBO], swarm, problem, verbose=0)
    println(best_score)
end