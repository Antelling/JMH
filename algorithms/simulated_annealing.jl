function simulated_annealing(system::Vector{Float64}, f::Function;
        range::Number=1, temp::Number=-1.0, cooling_rate::Float64=.85, min_temp::Float64=.01,
        verbose::Bool=false)

    #keep the state of the current system
    prev_score = Inf
    prev_system = system

    #keep the state of the best system seen
    best_score = Inf
    best_system = Vector{Float64}()

    if temp < 0

    end

    while true
        new_system::Vector{Float64} = prev_system + (range * 2) .* (rand(length(system)) .- .5)
        new_score = f(new_system)
        change_in_energy = new_score - prev_score

        if change_in_energy < 0 #a decrease in energy of the system
            prev_system = new_system
            prev_score = new_score
        else #the energy increased, but we accept it based on the metropolis algorithm
            metropolis = 2.71^(-change_in_energy/temp)
            if rand() < metropolis
                prev_system = new_system
                prev_score = new_score
            end
        end

        #handle saving best found
        if new_score < best_score
            best_score = new_score
            best_system = new_system
            if verbose println("\e[106m\e[30m$(new_score)\e[0m: $(new_system)") end
        end

        #now we apply the cooling factor
        temp *= cooling_rate
        if temp < min_temp
            return best_system
        end
    end
end
