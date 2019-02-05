"""if we sample with a biased probability, a normal distribution of turned on
bits will be created. Our bias directly informs the mean. The number of
variables informs the standard deviation."""
function random_init(problem::ProblemInstance, n_solutions::Int=50; verbose=0, repair=true)
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


"""Add items to a BitList until an upper bound is violated, then remove those items until a valid
solution is found"""
function build_remove_init(problem::ProblemInstance, n_solutions::Int=50; verbose=0)
    n_dimensions = length(problem.objective)

    valid_solutions = Set{BitList}()
    while length(valid_solutions) < n_solutions
        potential_solution::BitList = [false for i in 1:n_dimensions]
        while violates_upper(potential_solution, problem) == 0
            i = rand(1:n_dimensions)
            #this has a chance of flipping true to false, but it doesn't matter
            potential_solution[i] = !potential_solution[i]
        end
    end
end


using Random
"""FIXME: This doesn't work at all"""
function recursive_init(problem::ProblemInstance, n_solutions::Int=50; verbose=0)
    n_dimensions = length(problem.objective)

    valid_solutions = Set{BitList}()
    while length(valid_solutions) < n_solutions
        index_list = randperm(n_dimensions)
        i = 1
        potential_solution::BitList = [false for i in 1:n_dimensions]
        while i < n_dimensions
            potential_solution[index_list[i]] = true
            if violates_lower(potential_solution, problem) > 0
                #solution is too small, wait for it to grow
                if verbose >= 3
                    print("👿") #there's a little devil emoji here but it doesn't always render
                end
            elseif violates_upper(potential_solution, problem) > 0
                #solution is too large, undo the last change
                potential_solution[index_list[i]] = false
                if verbose >= 3
                    print("👿") #there's a little devil emoji here but it doesn't always render
                end
            else
                #solution is valid
                push!(valid_solutions, potential_solution)
                if verbose >= 2
                    print("😄")
                end
                break
            end
            i+= 1
        end
    end
    return valid_solutions
end
