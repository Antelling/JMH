

include("helpers/euc_distance.jl")

function dynamic(n)
    cache = Dict{Vector{Vector{Int}}, Float64}()
    total = 0
    for x in 1:n
        point1 = rand(1:10, 2)
        point2 = rand(1:10, 2)
        points = [point1,point2]
        value = get(cache, points, -1.0)
        if !(value == -1.0)
            total += cache[points]
            print("h")
        else
            print(" ")
            dist = euc_distance(point1..., point2...)
            cache[points] = dist
            total += cache[points]
        end
    end
    return total
end

function linear(n)
    total = 0
    for x in 1:n
        total += euc_distance(rand(1:4, 4)...)
    end
    return total
end

dynamic(14000)
linear(5000)

#@time dynamic(20000000)
#@time linear(20000000)
