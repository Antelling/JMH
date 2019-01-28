using ForwardDiff
function gradient_descent(f::Function, starting_point::Vector{<:Real}; dx::Float64=.001, convergence::Float64=.001)
    while true
        diff = ForwardDiff.gradient(f, starting_point) .* dx
        starting_point .+= diff
        if max(diff...) < convergence
            return starting_point
        end
    end
end
