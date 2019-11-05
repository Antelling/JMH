include("framework/structs.jl")
include("framework/load_datasets.jl")
include("framework/problem_properties.jl")
include("algorithms/repair_op.jl")
include("framework/solution_validity.jl")

const problems_dir = "beasley_mdmkp_datasets/"
const dataset = 7
const case = 3
const problem_num = 1

const problem_index = (problem_num - 1)* 6 + case

const problems = parse_file(problems_dir * "mdmkp_ct$(dataset).txt")
const problem = problems[problem_index]

function attempt()
    starting_weights = open("simplex_lp_ds7_i3.csv")
    data = read(starting_weights, String)
    data = split(data, "\n")[1]
    data = split(data, ",")
    weights = [parse(Float64, d) for d in data]

    valid_solutions = Set{BitList}()

    while length(valid_solutions) < 5
        new_solution = [rand() < percent for percent in weights]
        val = is_valid(new_solution, problem)
        if !val
            val, new_solution = VSRO(new_solution, problem)
            if !val
                continue
            end
        end

        println(new_solution)
        append!(valid_solutions, new_solution)
    end
end

attempt()
