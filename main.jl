include("loss_functions/traveling_salesman.jl")
include("helpers/euc_distance.jl")
include("optimizers/gradient_descent.jl")

function search_salesman(n_params::Int, data; attempts::Int=9999999)
    best_s = Vector{Float64}()
    best_score = Inf

    for _ in 1:attempts
        s = rand(n_params)
        s = gradient_descent(continuous_score, s)

        reference_s = sort(s)
        integer_system::Vector{Int} = []
        for item in s
            push!(integer_system, findfirst(x->x==item,reference_s))
        end

        println(s)
        println(integer_system)

        new_score = score(integer_system, data)
        if new_score < best_score
            best_score = new_score
            best_s = integer_system
            println("\e[105m\e[30m$(best_score)\e[0m: $(best_s)")
        end
    end
end

search_salesman(100, small_cities, attempts=1000)
