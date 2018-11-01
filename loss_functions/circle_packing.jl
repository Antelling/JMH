#try to minimize the free energy of a system of circles centered around the origin

const diameters = [1, 1, 2, 2, 3, 4, 4, 4, 5, 6, 7, 7, 8, 8, 8, 8] # $10,000 sequence

function score(system::Vector{Float64})::Float64

    free_energy = 0.0

    for i in 1:length(diameters) #compare every circle to every other circle to make sure there are no collisions
        x1 = system[i * 2 - 1]
        y1 = system[i * 2]
        for j in (i+1):length(diameters) #we don't need to compare twice
            x2 = system[j * 2 - 1]
            y2 = system[j * 2]
            dist = euc_distance(x1, y1, x2, y2)
            min_dist = diameters[i]/2 + diameters[j]/2
            if dist < min_dist
                free_energy += (min_dist - dist) * 1000
            end
        end
    end

    for (i, diameter) in enumerate(diameters)
        x = system[i * 2 - 1]
        y = system[i * 2]
        h = euc_distance(x, y, 0.0, 0.0)^2
        free_energy += h * pi*(diameter/2)^2
    end

    return free_energy
end
