function random_walk(system::Vector{Float64}, f::Function; range::Number=1)
    best_score = Inf
    while true
        new_system::Vector{Float64} = system + (2 * range) .* (rand(length(system)) .- .5)
        s = f(new_system)
        if s < best_score
            system = new_system
            best_score = s
            println("\e[106m\e[30m$(s)\e[0m: $(sys)")
        end
    end
end