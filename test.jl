include("libraries/BloomFilter/bloom-filter.jl")

import Base.push!, Base.in
push!(a::BloomFilter, b) = add!(a, b)
in(a::BloomFilter, b) = contains(a, b)

function test_insertion(collection, n::Int)
    for x in 1:n
        push!(collection, rand(5))
    end

    return collection
end

function test_containment(data, n::Int)
    total = 0
    for x in 1:n
        total += in(rand(5), data)
    end
    return total
end

for collection in [Set{Vector{Float64}}(), BloomFilter(100000, .005)]
    println("testing $(collection)")

    test_insertion(collection, 100)
    @time data = test_insertion(collection, 100000)

    test_containment(data, 100)
    @time collisions = test_containment(data, 10000000)

end
