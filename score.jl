#okay so these circles are going to have widths given by:
#1, 1, 2, 3, 5, and 7
#we are going to try and minimize the free energy of that system when it is centered around a
#singularity, eg given the point (0, 0) and the positions of each of those 6 circles, the free
#energy of one sphere is it's mass times its height, where its mass is pi*r^2, and its height is
#sqrt(x^2 + y^2).

System = Vector{Float64}
const diameters = [1, 1, 2, 3, 5, 7]

function euc_distance(x1::Float64, y1::Float64, x2::Float64, y2::Float64)::Float64
    return sqrt((x1 - x2)^2 + (y1 - y2)^2)
end


function score(system::System)::Float64
    for i in 1:6 #compare every circle to every other circle to make sure there are no collisions
        x1 = system[i * 2 - 1]
        y1 = system[i * 2]
        for j in i:6 #we don't need to compare twice
            x2 = system[j * 2 - 1]
            y2 = system[j * 2]
            dist = euc_distance(x1, y1, x2, y2)
            min_dist = diameters[i] + diameters[j]
            if dist < min_dist
                return 999999.0 #don't return an error since not all optimizers have handlers, just
                #return a large number so this isn't a used solution
            end
        end
    end

    free_energy = 0.0

    for (i, weight) in enumerate(diameters)
        x = system[i * 2 - 1]
        y = system[i * 2]
        h = euc_distance(x, y, 0.0, 0.0)
        free_energy += h * weight
    end

    return free_energy
end
