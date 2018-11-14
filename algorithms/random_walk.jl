function random_walk(system::Vector{Float64}, f::Function; range::Number=1, max_failed_attempts::Int=1000, verbose::Bool=false)
    best_score = Inf
    failed_attempts = 0
    while true
        new_system::Vector{Float64} = system + (2 * range) .* (rand(length(system)) .- .5)
        s = f(new_system)
        failed_attempts += 1
        if s < best_score
            system = new_system
            best_score = s
            failed_attempts = 0
            if verbose println("\e[106m\e[30m$(s)\e[0m: $(sys)") end
        end
        if failed_attempts > max_failed_attempts
            return system
        end
    end
end
