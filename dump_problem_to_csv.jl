include("framework/structs.jl")
include("framework/load_datasets.jl")
include("framework/problem_properties.jl")

const problems_dir = "beasley_mdmkp_datasets/"
dataset = 7
case = 3
problem_num = 1

problem_index = (problem_num - 1)* 6 + case

problems = parse_file(problems_dir * "mdmkp_ct$(dataset).txt")
problem = problems[problem_index]

function get_csv(problem::ProblemInstance)
    output = ""
    output *= join(problem.objective, ",") * "\n\n"

    for lower_bound in problem.lower_bounds
        output *= join(lower_bound[1], ",") * "," * string(lower_bound[2]) * "\n"
    end
    output *= "\n"
    for bound in problem.upper_bounds
        output *= join(bound[1], ",") * "," * string(bound[2]) * "\n"
    end

    output *= "\n\n" * join(get_solution_range(problem), ",")
end


csv = get_csv(problem)
file = open("csv_dump.csv", "w")
write(file, csv)
close(file)
