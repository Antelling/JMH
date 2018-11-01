using Luxor

const scale = 19

function graph(system::Vector{Float64})
    sorted_cities = sort(cities, by=i->system[i])
    Drawing(1000, 1000, "graph2.png")
    background("white")
    sethue("black")

    for i in 1:length(cities)-1
        x1, y1 = sorted_cities[i]
        x2, y2 = sorted_cities[i+1]
        line(Point(x1*scale, y1*scale), Point(x2*scale, y2*scale), :stroke)
    end

    finish()
    preview()
end
