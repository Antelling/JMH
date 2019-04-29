include("parse_data.jl")

include("initial_pop.jl")
include("eval_solution.jl")
include("eval_problem.jl")
include("repair_op.jl")

include("alg_coordinator.jl")
include("gen_jaya.jl")

function feas_score(solution::BitList, problem::ProblemInstance)
    #our optimization functions are looking for the highest possible score
    #so we want feasible solutions to return a positive
    #and infeasible to return a negative
    #we will keep track of both feasibility and infeasibility
    #and return infeasibility if it is non zero, else feasibility

    feasibility = 0
    infeasibility = -0
    for upper_bound in problem.upper_bounds
        violation = sum(upper_bound[1] .* solution) - upper_bound[2]
        if violation > 0
            infeasibility -= violation
        else
            feasibility += abs(violation^2)
        end
    end
    for lower_bound in problem.lower_bounds
        violation = lower_bound[2] - sum(lower_bound[1] .* solution)
        if violation > 0
            infeasibility -= violation
        else
            feasibility += abs(violation^2)
        end
    end

    if infeasibility == 0
        return feasibility
    else
        return infeasibility
    end
end

function initial_jaya(problem::ProblemInstance, n_sol)::Swarm
    #for the initial swarm, we steal the probability calculation method from
    #initial pop
    r = get_solution_range(problem)
    v = length(problem.objective)
    percentage = sum(r)/(2v)

    valid_solutions = Set{BitList}()

    while length(valid_solutions) < n_sol

        possible_solutions = Set{BitList}()

        while length(possible_solutions) < 30
            push!(possible_solutions, map(i->i<percentage, rand(v)))
        end

        swarm::Swarm = collect(possible_solutions)

        optimizer::Function = iterate_monad(gen_jaya_monad(repair=false, feasibility_check=(i,j)->true, score=feas_score))
        new_swarm::Swarm = optimizer(deepcopy(swarm), problem)[1]

        for i in 1:length(swarm)
            if is_valid(new_swarm[i], problem)
                push!(valid_solutions, new_swarm[i])
            end
        end
    end

    return collect(valid_solutions)
end

function bench()
    easy_problem = parse_file("data/mdmkp_ct1.txt")[1]

    random_init(easy_problem, 20, repair=true, repair_op=VSRO)
    dimensional_focus(easy_problem, 20, repair=true, repair_op=VSRO)
    initial_jaya(easy_problem, 20)

    for ds in 1:9
        println(ds)
        problem = parse_file("data/mdmkp_ct$(ds).txt")[1]
        @time random_init(problem, 20, repair=true, repair_op=VSRO)
        @time dimensional_focus(problem, 20, repair=true, repair_op=VSRO)
        @time initial_jaya(problem, 20)
    end
end

bench()
