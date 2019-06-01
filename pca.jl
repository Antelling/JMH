include("framework/structs.jl")
include("framework/load_datasets.jl")
include("framework/problem_properties.jl")
include("framework/solution_validity.jl")
include("framework/swarm_properties.jl")

include("algorithms/repair_op.jl")
include("algorithms/hybrids.jl")
include("algorithms/gen_initial_pop.jl")
include("algorithms/alg_coordinator.jl")
include("algorithms/jaya.jl")
include("algorithms/tlbo.jl")
include("algorithms/ga.jl")
include("algorithms/local_search.jl")

import JSON
using Dates: today
# import Random

const problems_dir = "beasley_mdmkp_datasets/"

using JSON

const name = "G2JG4TL"

function main(n)
    dataset = 1
    problem = 3

    problem = parse_file(problems_dir * "mdmkp_ct$(dataset).txt")[problem]
    X = greedy_construct(problem, n, repair_op=VSRO, local_search=identity, max_attempts=500_000)
    X = iterate_monad(G2JG4TL_monad(local_search=identity), n_fails=25, time_limit=60)(X, problem)[1]
    y = [[score_solution(x, problem)] for x in X]

    open(name * ".json", "w") do f
        write(f, JSON.json([X, y], 4))
    end
end


main(1)
main(500)
run(`python3 _pca.py $(name)`)
run(`rm $(name).json`)
