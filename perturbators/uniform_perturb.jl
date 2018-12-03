function uniform_generator(min::Real, max::Real)
    uniform_dist = function(n::Int) rand(n) .* (max - min) .+ min end
    return function(system::Vector{<:Real}) system .+ uniform_dist(length(system)) end
end
