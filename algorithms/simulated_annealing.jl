using Statistics: std

function simulated_annealing(
        system::Vector{Float},
        f::Function;
        range::Real=1,
        temp::Real=-1.0,
        acceptance_rate::Float=.5,
        cooling_rate::Float=.9,
        accept_max::Int=12,
        attempt_max::Int=12,
        failed_temp_stages_max::Int=3,
        verbose::Bool=false)
    """
    This implementation of simulated annealing is based on the second chapter of:
    Siarry, Patrick. Metaheuristics. Springer, 2016.
    Fucking yeet.
    """

    n_params = length(system)

    #keep the state of the current system
    prev_score = Inf
    prev_system = system

    #keep the state of the best system seen
    best_score = Inf
    best_system = Vector{Float64}()

    if temp < 0
        energies::Vector{Float64}()
        for i in 1:100
            push!(energies, f(prev_system + (range * 2) .* (rand(n_params) .- .5)))
        end
        st_dev = std(energies, corrected=false)
        #Siarry gives a formula for estimating initial temp as
        #e^(-std_dev/temp) = acceptance_rate, where acceptance_rate should be
        #.5 if the initial system is poor, and .2 if it's good. We rearrange
        #that formula into:
        temp = -std_dev/log(acceptance_rate)
    end

    accepted_perturbations = 0
    attempted_perturbations = 0
    failed_temp_stages = 0

    accept_max *= n_params
    attempt_max *= n_params #the criteria for moving to the next temp stage is
    #dependent on the degrees of ffreedom of the problem (Siarry p. 39)

    while true
        attempted_perturbations += 1

        new_system::Vector{Float64} = prev_system + (range * 2) .* (rand(n_params) .- .5)
        new_score = f(new_system)

        change_in_energy = new_score - prev_score

        #accept based on metropolis algorithm (Siarry p. 21)
        if change_in_energy <= 0 or rand() < 2.71^(-change_in_energy/temp)
            prev_system = new_system
            prev_score = new_score
            accepted_perturbations += 1
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
