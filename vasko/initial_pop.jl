#FIXME: make vasko's and benchmark repair

"""if we sample with a biased probability, a normal distribution of turned on
bits will be created. Our bias directly informs the mean. The number of
variables informs the standard deviation."""
function random_init(problem::ProblemInstance, n_solutions::Int=50; verbose::Int=0, repair::Bool=false, repair_op::Function=Pass)
    orig_p = "$(problem)"
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
            if repair
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

"""Add items to a knapsack until all dimensional constraints are violated, then """
function dimensional_focus(problem::ProblemInstance, n_solutions::Int=50; verbose=0)
    n_dimensions = length(problem.objective)

    valid_solutions = Set{BitList}()
    while length(valid_solutions) < n_solutions
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
        if !violates_demands(solution, problem)
            push!(valid_solutions, solution)
        end
    end
    return collect(valid_solutions)
end
