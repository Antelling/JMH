include("structs.jl")

function parse_file(filename)
    f = open(filename)

    problems::Vector{ProblemInstance} = []

    #the very first item in the array is the amount of problems found in the
    #file.
    amount_of_problems = next_line(f)[1]

    #so now for every problem:
    problem_index = 1
    for problem in 1:amount_of_problems
        n, m = next_line(f)
        lower_than_values::Vector{Vector{Int}} = []
        for i in 1:m
            push!(lower_than_values, next_line(f))
        end
        lower_than_constraints::Vector{Int} =  next_line(f)
        greater_than_values::Vector{Vector{Int}} = []
        for i in 1:m
            push!(greater_than_values, next_line(f))
        end
        greater_than_constraints = next_line(f)
        cost_coefficient_values::Vector{Vector{Int}} = []
        for i in 1:6
            push!(cost_coefficient_values, next_line(f))
        end

        upper_bounds::Vector{Tuple{Vector{Int},Int}} = []
        lower_bounds::Vector{Tuple{Vector{Int},Int}} = []

        for i in 1:m
            push!(lower_bounds, (greater_than_values[i], greater_than_constraints[i]))
            push!(upper_bounds, (lower_than_values[i], lower_than_constraints[i]))
        end

        q = [1, div(m, 2), m, 1, div(m, 2), m]
        for i in 1:6
            push!(problems, ProblemInstance(
                cost_coefficient_values[i],
                upper_bounds,
                lower_bounds[1:q[i]],
                problem_index
            ))
            problem_index += 1
        end
    end

    return problems
end

function next_line(file::IOStream)
    return parse_line(readline(file))
end

function parse_line(line)
    return map(parse_int, split(line))
end

function parse_int(x)
    return parse(Int, x)
end
