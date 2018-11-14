using Luxor

const scale = 10

function graph(system::Vector{Float64})
    Drawing(1000, 1000, "visuals/circles_graph.png")
    background("white")
    sethue("black")
    origin()

    for (i, weight) in enumerate(diameters)
        x = system[i * 2 - 1]
        y = system[i * 2]
        d = weight/2
        circle(x*scale, y*scale, d*scale, :fill)
    end

    finish()
end

graph([4.95153, -27.1478, 22.0206, -17.8985, 10.2271, 12.2632, -6.87096, 14.5253, -10.4084, -13.0357, -12.8859, 0.14417, 11.6916, -9.38842, 0.888033, 12.1009, -9.43157, 3.41516, 4.15891, 7.65798, 6.94662, -5.93164, 0.3379, -8.76853, -6.7267, -2.71155, -3.18522, 5.90246, 1.0543, -0.788279, 8.95453, 2.04522])
