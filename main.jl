include("loss_functions/traveling_salesman.jl")
include("helpers/euc_distance.jl")
include("algorithms/random_walk.jl")
include("algorithms/random_sample.jl")
include("algorithms/simulated_annealing.jl")

function search()
    best_s = Vector{Float64}()
    best_score = Inf
    while true
        s = random_sample(score, 100)
        s = simulated_annealing(s, score, temp=100, cooling_rate=.999, min_temp=.001)
        new_score = score(s)
        if new_score < best_score
            best_score = new_score
            best_s = s
            println("\e[105m\e[30m$(best_score)\e[0m: $(best_s)")
        end
    end
end

search()
