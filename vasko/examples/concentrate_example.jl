include("parse_data.jl")

include("initial_pop.jl")
include("eval_solution.jl")
include("eval_problem.jl")
include("repair_op.jl")

function concentrate()
    problem = ProblemInstance([1, 2, 3, 4, 5],
     [([11, 22, 33, 44, 55], 76)],
     [([55, 44, 33, 22, 11], 32)],
     1)

    swarm3::Swarm = [[true, false, false, false, true]]

    smol_problem = concentrate(swarm3, problem)

    println(smol_problem)
end

function repair()
    problem = parse_file("data/mdmkp_ct1.txt")[3]
    random_init(problem, 20, repair=true, repair_op=VSRO)

    for dataset in 9:-1:1
        problem = parse_file("data/mdmkp_ct$(dataset).txt")[3]
        @time random_init(problem, 5, repair=true, repair_op=VSRO)
    end

end

repair()
