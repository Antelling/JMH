function test_insertion(type::Type, n::Int)
    tl = type{Vector{Float64}}()

    for x in 1:n
        push!(tl, rand(5))
    end

    return tl
end

function test_containment(data, n::Int)
    total = 0
    for x in 1:n
        total += in(rand(5), data)
    end
    return total
end

for type in [Set, Vector]
    println("testing $(type)")

    test_insertion(type, 100)
    @time data = test_insertion(type, 10000)

    test_containment(data, 100)
    @time collisions = test_containment(data, 100000)

end
