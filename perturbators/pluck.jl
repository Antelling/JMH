function pluck(system::Vector{<:Real})
    l = length(system)
    plucked = rand(1:l-1)

    return vcat(system[1:plucked-1], system[plucked+1:end], system[plucked])
end

function pluck_generator(n::Int)
    return function(data)
        for _ in 1:n
            data = pluck(data)
        end
        return data
    end
end 
