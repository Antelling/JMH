using Luxor

const scale = 10

function graph(system::Vector{Float64})
    @png begin
        sethue("black")
        for (i, weight) in enumerate(diameters)
            x = system[i * 2 - 1]
            y = system[i * 2]
            d = weight/2
            circle(x*scale, y*scale, d*scale, :fill)
        end
    end
end