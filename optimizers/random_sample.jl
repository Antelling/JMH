function random_sample(f::Function, n_args::Int64; range::Number=50, n_tries::Int64=200, verbose::Bool=false)
    best_score = Inf
    best_sys = []
    for i in 1:n_tries
        sys::Vector{Float64} = (rand(n_args) .- .5) .* (2 * range)
        s = f(sys)
        if s < best_score
            best_sys = sys
            best_score = s
            if verbose println("\e[106m\e[30m$(s)\e[0m: $(sys)") end
        end
    end
    return best_sys
end