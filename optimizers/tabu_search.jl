function tabu_search(
system::Vector{<:Real},
score_f::Function,
perturb_f::Function;
tl_type=Vector{<:Real}(),
n_tries::Int=100000,
n_neighbors::Int=15,
verbose::Int=0)

    best_system = copy(system)
    best_score = score_f(system)
    for i in 1:n_tries

        best_neighbor_score = Inf
        best_local_neighborhood = copy(system)
        for j in 1:n_neighbors
            neighbor = perturb_f(system)
            neighbor_score
        end

    end
end
