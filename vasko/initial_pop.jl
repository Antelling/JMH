include("structs.jl")
include("eval_solution.jl")

"""if we sample with a biased probability, a normal distribution of turned on
bits will be created. Our bias directly informs the mean. The number of
variables informs the standard deviation."""
function random_initialize(problem::ProblemInstance, n_solutions::Int=50; verbose=0)
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
            if verbose >= 3
                print("👿")
            end
            fails += 1
        end
    end
    if verbose >= 1
        println("\n$(n_solutions) solutions found, success rate of $(round(10000*passes/(passes+fails))/100)%, exiting")
    end
    return collect(valid_solutions) #turn from set into vector FIXME: discuss with Vasko
end

#TODO: implement Vasko's method
#TODO: implement backtrack method
#TODO: benchmark the methods
