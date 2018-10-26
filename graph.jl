using Luxor

const scale = 20

function graph(system::System)
    @png begin
        sethue("black")
        for (i, weight) in enumerate(weights)
            x = system[i * 2 - 1]
            y = system[i * 2]
            d = weight/2
            circle(x*scale, y*scale, d*scale, :fill)
        end
    end
end