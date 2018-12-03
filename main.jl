include("loss_functions/traveling_salesman.jl")
include("helpers/euc_distance.jl")
include("optimizers/simulated_annealing.jl")
include("perturbators/random_swap.jl")

function search_salesman(attempts::Int=9999999)
    best_s = Vector{Float64}()
    best_score = Inf

    for _ in 1:attempts
        s = Array(1:length(cities))
        s = simulated_annealing(s, score, random_swap, attempt_max=200, acceptance_rate=.2, failed_temp_stages_max=5, cooling_rate=.93)
        s = simulated_annealing(s, score, point_swap, acceptance_rate=.1, cooling_rate=.95, failed_temp_stages_max=5)

        new_score = score(s)
        if new_score < best_score
            best_score = new_score
            best_s = s
            println("\e[105m\e[30m$(best_score)\e[0m: $(best_s)")
        end
    end
end

search_salesman()
