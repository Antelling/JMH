include("parse_data.jl")

include("initial_pop.jl")
include("eval_solution.jl")
include("eval_problem.jl")
include("repair_op.jl")

include("alg_coordinator.jl")
include("jaya.jl")
include("tlbo.jl")

function bench_monads(swarm, problem, n)
    j = jaya_monad(repair=false)
    l = LBO_monad(repair=false)
    t = TBO_monad(repair=true, repair_op=VSRO)
    totals = 0
    for alg in [j, l, t]
        for x in 1:n
            totals += alg(deepcopy(swarm), problem)[2]
        end
    end
    return totals
end

function bench_direct(swarm, problem, n)
    totals = 0
    for x in 1:n
        totals += jaya(deepcopy(swarm), problem, repair=false)[2]
    end
    for x in 1:n
        totals += LBO(deepcopy(swarm), problem, repair=false)[2]
    end
    for x in 1:n
        totals += TBO(deepcopy(swarm), problem, repair=true, repair_op=VSRO)[2]
    end
    return totals
end

problem = parse_file("data/mdmkp_ct1.txt")[1]
swarm = random_init(problem, 100, repair=false)

bench_monads(swarm, problem, 1)
bench_direct(swarm, problem, 1)

@time bench_monads(swarm, problem, 1000)
@time bench_direct(swarm, problem, 1000)
