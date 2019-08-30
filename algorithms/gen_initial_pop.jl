"""if we sample with a biased probability, a normal distribution of turned on
bits will be created. Our bias directly informs the mean. The number of
variables informs the standard deviation."""
function random_init(problem::ProblemInstance, n_solutions::Int=50; verbose::Int=0, repair_op::Function=VSRO)
    r = get_solution_range(problem)
    v = length(problem.objective)
    percentage = sum(r)/(2v)
    valid_solutions = Set{BitList}()
    if verbose >= 1
        println("generating random possible solutions with $(percentage*100)% chance of true dimension")
    end
    passes = 0
    fails = 0
    while length(valid_solutions) < n_solutions
        possible_solution::BitList = map(i->i<percentage, rand(v))
        if is_valid(possible_solution, problem)
            push!(valid_solutions, possible_solution)
            if verbose >= 2
                print("😄")
            end
            passes += 1
        else
            valid, possible_solution = repair_op(possible_solution, problem)
            if valid
                push!(valid_solutions, possible_solution)
                if verbose >= 2
                    print("😊")
                end
                passes += 1
            elseif verbose >= 3
                print("👿") #there's a little devil emoji here but it doesn't always render
            else
                fails += 1
            end
        end
    end
    if verbose >= 1
        println("\n$(n_solutions) solutions found, success rate of $(round(10000*passes/(passes+fails))/100)%, exiting")
    end
    return collect(valid_solutions)
end

using Random: randperm

"""Add items to a knapsack until all dimensional constraints are violated, then
see if it is valid. If it is not, optionally repair it."""
function greedy_construct(problem::ProblemInstance, n_solutions::Int=50; verbose::Int=0, repair_op::Function=VSRO,
            local_search::Function=identity,
            max_attempts::Int=50_000, max_time::Int=60)
    n_dimensions = length(problem.objective)

    valid_solutions = Set{BitList}()
    attempts = 0
    start_time = time()
    while length(valid_solutions) < n_solutions && attempts < max_attempts && (time() - start_time) < max_time
        attempts+=1

        order = randperm(n_dimensions)

        solution::BitList = zeros(Int, n_dimensions)
        dimensions = zeros(Int, length(problem.upper_bounds))
        for i in order
            valid = true
            for (j, bound) in enumerate(problem.upper_bounds)
                if dimensions[j] + bound[1][i] > bound[2]
                    valid = false
                end
            end
            if valid
                for (j, bound) in enumerate(problem.upper_bounds)
                    dimensions[j] += bound[1][i]
                end
                solution[i] = true
            end
        end
        generated_check(violates_demands, solution, valid_solutions, problem,
                repair_op, local_search, verbose)

        if length(valid_solutions) == n_solutions
            break
        end

        demand_solution::BitList = ones(Int, n_dimensions)
        dimensions = [sum(bound[1]) for bound in problem.lower_bounds]
        for i in order
            valid = true
            for (j, bound) in enumerate(problem.lower_bounds)
                if dimensions[j] - bound[1][i] < bound[2]
                    valid = false
                end
            end
            if valid
                for (j, bound) in enumerate(problem.lower_bounds)
                    dimensions[j] -= bound[1][i]
                end
                demand_solution[i] = false
            end
        end
        generated_check(violates_dimensions, demand_solution, valid_solutions, problem,
                repair_op, local_search, verbose)
    end
    return collect(valid_solutions)
end

function generated_check(check_function::Function, solution::BitList,
            valid_solutions::Set{BitList}, problem::ProblemInstance,
            repair_op::Function,
            local_search::Function,
            verbose::Int)
    if !check_function(solution, problem)
        push!(valid_solutions, local_search(solution, problem))
        if verbose > 0
            print("*")
        end
    else
        v, sol = repair_op(solution, problem)
        if v
            push!(valid_solutions, local_search(sol, problem))
            if verbose > 0
                print("*")
            end
        end
    end
end
