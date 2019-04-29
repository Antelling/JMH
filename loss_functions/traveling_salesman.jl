using StatsBase: AnalyticWeights, mean

include("traveling_salesman_data.jl")

function score(params::Vector{Int}, data::Vector{Vector{Int}})
    total = 0.0
    for i in 1:length(params) - 1
        total += euc_distance(data[params[i]]..., data[params[i + 1]]...)
    end
    total += euc_distance(data[params[1]]..., data[params[end]]...)
    return(total)
end

function score(params::Vector{Float64}, data::Vector{Vector{Int}})
    cities = sort_cities(params, data)
    total = 0.0
    for i in 1:length(cities) - 1
        total += euc_distance(cities[i].city..., cities[i+1].city...)
    end
    total += euc_distance(cities[1].city..., cities[end].city...)
    return(total)
end

function score(data::Vector{Vector{Int}})
    total = 0.0
    for i in 1:length(data) - 1
        total += euc_distance(data[i]..., data[i+1]...)
    end
    total += euc_distance(data[1]..., data[end]...)
    return(total)
end

function fast_fake_score(params::Vector{Int}, data::Vector{Vector{Int}})
    return params[1]/params[2] + params[3]
end

struct order_city_pair
    order::Real
    city::Vector{Int}
end

function sort_cities(params::Vector{<:Real}, data::Vector{Vector{Int}})
    paired_data::Vector{order_city_pair} = []
    for i in 1:length(data)
        push!(paired_data, order_city_pair(params[i], data[i]))
    end

    sort!(paired_data, by=i->i.order)

    return paired_data
end

function continuous_score(params::Vector{<:Real})
    data = small_cities
    cities = sort_cities(params, data)

    scores = Vector{Float64}()
    distances = Vector{Real}()

    #we need a list of all the differences
    #one over differences
    for i in 1:length(cities)-2
        d = cities[i+1].order - cities[i].order
        d = log(d)
        d = 1/d
        distance = euc_distance(cities[i].city..., cities[i+2].city...)

        push!(scores, distance)
        push!(distances, d) #this is confusing
    end

    sum_d = sum(distances)
    #okay so we want the sum of scores times the respective d/sum_d
    total = 0
    for i in 1:length(distances)
        total += scores[i] * (distances[i]/sum_d)
    end
    return total
end

using Distributions
function weighted_continous_score(params::Vector{<:Real}, dist::Sampleable) #, data::Vector{Vector{Int}})
    data = small_cities

    samples = Dict{Vector{Vector{Int}},Int}()
    for x in 1:1000
        new_params = params .+ rand(dist, length(params))
        pairs = sort_cities(new_params, data)
        cities = Vector{Vector{Int}}()
        for pair in pairs
            push!(cities, pair.city)
        end
        if haskey(samples, cities)
            samples[cities] += 1
        else
            samples[cities] = 1
        end
    end

    frequencies = Vector{Int}()
    distances = Vector{Float64}()
    for (key, value) in samples
        push!(frequencies, value)
        push!(distances, score(key))
    end

    weights = AnalyticWeights(frequencies)
    return mean(distances, weights)
end

using PyPlot
function graph()
    data = rand(length(small_cities))
    a = 50
    for distribution in [Normal(0, .03)]
        s = 0
        values::Vector{Float64} = []
        for x in 1:a
            println(x)
            data[1] = s
            s += 1/a
            push!(values, weighted_continous_score(data, distribution))
        end
        plot(values, label="Variance: $(distribution)")
    end
    legend()
    show()
end


include("../helpers/euc_distance.jl")
#graph()
#weighted_continous_score(rand(100))
