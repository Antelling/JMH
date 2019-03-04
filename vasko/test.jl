include("parse_data.jl")

include("initial_pop.jl")
include("eval_solution.jl")
include("eval_problem.jl")
include("repair_op.jl")

function main()
    problem = parse_file("data/mdmkp_ct1.txt")[3]

    swarm1::Swarm = random_init(problem, 1, repair=false)
    swarm2::Swarm = random_init(problem, 1, repair=true, repair_op=VSRO)
    swarm3::Swarm = dimensional_focus(problem, 1)

    @time swarm3 = dimensional_focus(problem, 20)
    @time swarm1 = random_init(problem, 20, repair=false)
    @time swarm2 = random_init(problem, 20, repair=true, repair_op=VSRO)


    for solution in swarm3
        @assert is_valid(solution, problem)
    end
end

function bench(n, p)
    dimensional_focus(p, n)
end

function t(n, p)
    start_time = time_ns()
    bench(n, p)
    end_time = time_ns()
    elapsed_time = (end_time - start_time)/(10^9)
    println(elapsed_time)
end

problem = parse_file("data/mdmkp_ct5.txt")[51]
t(1, problem)

#main()
