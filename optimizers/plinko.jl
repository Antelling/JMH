using Distributions
using StatsBase: AnalyticWeights, mean
include("../helpers/euc_distance.jl")

include("../loss_functions/traveling_salesman_data.jl") #fixme bad bad bad globals are bad

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

function score(data::Vector{Vector{Int}})
    total = 0.0
    for i in 1:length(data) - 1
        total += euc_distance(data[i]..., data[i+1]...)
    end
    total += euc_distance(data[1]..., data[end]...)
    return(total)
end

struct Int_float_pair
	int::Int
	float::Float64
end

struct Float_IntVec_pair
	float::Float64
	IntVec::Vector{Int}
end

function top_5(params::Vector{Float64})
    distance_matrix = Vector{Float_IntVec_pair}()
	for i in 1:length(params)
		for j in i+1:length(params)
			print("{$(i) to $(j)} ")
			d = abs(params[i] - params[j])
			push!(distance_matrix, Float_IntVec_pair(d, [i, j]))
		end
	end
	sort!(distance_matrix, by=x->x.float)
	println(distance_matrix[1:6])
end

function generate_possibility_tree(perturb_list::Vector{Float_IntVec_pair}, n_params::Int, prob_f::Function)
	#okay so we have a list of index swaps and the distance between them in the param space
	#we want to turn that distance into a probabilty with prob_f
	#we then construct a tree where everything either happens or it doesn't, and record the probabilities of each branch
	#we can then use that tree to get an average distance for this param space

	#instead of keeping track of the params directly,

	1 2 3 4 5

end

start_params = rand(length(small_cities))
top_5(start_params)

function sample_score(params::Vector{<:Real}, dist::Sampleable, score_f::Function, n_samples::Int)
    data = small_cities #fixme baaaaaaaaaaaaaaaaaaaaaaaaaaaad

    samples = Dict{Vector{Vector{Int}},Int}()
    for x in 1:n_samples
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
        push!(distances, score_f(key))
    end

    weights = AnalyticWeights(frequencies)
    return mean(distances, weights)
end

function plinko(
		system::Vector{<:Real},
		score_f::Function;
		dist::Sampleable=Normal(0, .02),
		detail::Int=150,
		n_samples::Int=1000,
		verbose::Int=0)

	while true
		best_value, best_score = 0.0, Inf
		for d in 1:length(system)
			val = 0.0
			m = max(system...)
			for i in 1:detail
				system[d] = val
				score = sample_score(system, dist, score_f, n_samples)
				if score < best_score
					best_score = score
					best_value = val
				end
				val += m/detail

				if verbose > 1
					println("dimension $(d) with value $(val) scores $(best_score)")
				end
			end
			system[d] = best_value
		end
		pairs = sort_cities(system, small_cities) #fixme atrocious shameful bad bad bad
        cities = Vector{Vector{Int}}()
        for pair in pairs
            push!(cities, pair.city)
        end
		if verbose > 0
			println("new system $(system) has an absolute score of $(score(cities))")
			println("")
		end
	end
end

plinko(start_params, score, n_samples=100, detail=50, verbose=1)
