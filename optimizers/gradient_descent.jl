using ForwardDiff
function gradient_descent(f::Function, starting_point::Vector{<:Real}; dx::Float64=.001, convergence::Float64=.00001)
    momentum = zeros(length(starting_point))
    while true
        diff = ForwardDiff.gradient(f, starting_point) .* dx
        momentum .+= diff
        momentum *= .5
        starting_point .-= (diff .+ momentum)
        if max(diff...) < convergence
            return starting_point
        end
    end
end
