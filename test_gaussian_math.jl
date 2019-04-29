#anything that autodiff will touch has to be type real
#we can strictly specify the stddev though
mutable struct Gaussian
    mean::Real
    stddev::Float64
    bounded_min::Bool
    bounded_max::Bool
    min::Real
    max::Real
    name::String
end

#we need a storage type for the discrete representations
#a single discrete system is a list of names
#we also need to store the probability of each system
#and we have numerous systems, where order does not matter
#so we need a set of discrete system and probability tuple pairs
Tree = Vector{Tuple{Vector{String},Real}}

Cities = Dict{String,Tuple{Int64,Int64}}

function Gaussian(mean, stddev, name="default")
    return Gaussian(mean, stddev, false, false, 0.0, 0.0, name)
end

using Distributions

#this is implicitly of type Cities
const data = Dict(
    "A"=>(1, 1),
    "B"=>(5, 3),
    "C"=>(7, 1),
    "D"=>(8, 8),
    "E"=>(5, 3),
    "F"=>(7, 7),
    "G"=>(9, 1),
    "H"=>(8, 3),
    "I"=>(5, 9),
    "J"=>(1, 2),
    "K"=>(1, 7),
    "L"=>(5, 2),
    "M"=>(7, 4),
    "N"=>(8, 7),
    "O"=>(5, 3),
    "P"=>(7, 2),
    "Q"=>(9, 5),
    "R"=>(8, 2),
    "S"=>(5, 4),
    "T"=>(1, 2),
)

function calculate_cdf(z, mean=0, stddev=1)
    return 1 - cdf.(Normal(mean, stddev), z)
end

function chance_a_gt_b(a::Gaussian, b::Gaussian)
    if ((!a.bounded_min) || (a.min < b.max)) && ((!b.bounded_max) || (b.max > a.min))
        new_mean = a.mean - b.mean
        new_stddev = sqrt(a.stddev^2 + b.stddev^2)
        return calculate_cdf(0, new_mean, new_stddev)
    else
        #println("not allowed: $(a) and $(b)")
        return 0.0
    end
end

function create_probability_tree(system::Vector{Gaussian})
    #first we sort the system by the mean of the variables
    sort!(system, by=i->i.mean)

    #now we need the first tree, which will have just one system with a
    #probability of 1.0
    tree = Tree()
    push!(tree, (map(i->i.name, system), 1.0))

    #now we want to get the 32 most likely changes
    #2^x == 32 when x == 5
    for x in 1:5
        #we find the most likely swap given the current system
        highest_percentage = 0.0
        indices = [0, 0]

        for i in 1:length(system)-1
            #if i and i+1 don't work, keep skipping over the second index
            second_i = i+1
            swap_chance = chance_a_gt_b(system[i], system[second_i])
            while swap_chance == 0 && second_i <= length(system)
                second_i += 1
            end
            if swap_chance > highest_percentage
                highest_percentage = swap_chance
                indices = [i, second_i]
            end
        end

        if indices == [0, 0]
            break
        end

        #okay so now we have the most likely swap
        #which either happens or it doesn't, for each system in our set
        new_tree = Tree()
        for (disc_sys, prob) in tree
            #case didn't happen
            push!(new_tree, (disc_sys, prob * (1-highest_percentage)))
            #case did happen
            other_disc_system = copy(disc_sys)
            other_disc_system[indices[1]], other_disc_system[indices[2]] = other_disc_system[indices[2]], other_disc_system[indices[1]]
            push!(new_tree, (other_disc_system, prob * highest_percentage))
        end

        #we we have to apply the swap to the continous system
        middle_ground = (system[indices[1]].mean + system[indices[2]].mean)/2
        system[indices[1]].bounded_min = true
        system[indices[1]].min = middle_ground + eps()
        system[indices[2]].bounded_max = true
        system[indices[2]].max = middle_ground - eps()

        #and now we swap it back
        tree = new_tree
    end

    return tree
end

function euc_distance(a::Tuple{Int64,Int64}, b::Tuple{Int64,Int64})
    return sqrt((a[1] - b[1])^2 + (a[2] - b[2])^2)
end

function score_system(system::Vector{String}, data::Cities)
    total = 0
    for i in 1:length(system)-1
        total += euc_distance(data[system[i]], data[system[i+1]])
    end
    return total
end

function score_probability_tree(tree::Tree, data::Cities)
    total = 0
    for branch in tree
        total += score_system(branch[1], data) * branch[2]
    end
    return total
end

function vector_score(means::Vector{<:Real})
    std = .2
    index = 'A'
    system::Vector{Gaussian} = []
    for mean in means
        push!(system, Gaussian(mean, std, "$(index)"))
        index += 1
    end
    tree::Tree = create_probability_tree(system)

    return score_probability_tree(tree, data)
end

function rand_samp_score(params::Vector{<:Real})
    dist = Normal(0, .02)
    samples = Dict{Vector{String},Int}()

    system::Vector{Tuple{String,Real}} = []
    ch = 'A'
    for param in params
        push!(system, ("$(ch)", param))
        ch += 1
    end

    for x in 1:300
        sample::typeof(system) = []
        for t in system
            push!(sample, (t[1], t[2] + rand(dist)))
        end

        sort!(sample, by=i->i[2])
        key::Vector{String} = []
        for s in sample
            push!(key, s[1])
        end

        if haskey(samples, sample)
            samples[sample] += 1
        else
            samples[sample] = 1
        end
    end

    frequencies = Vector{Int}()
    distances = Vector{Float64}()
    for (key, value) in samples
        push!(frequencies, value)
        push!(distances, score_system(key))
    end

    weights = AnalyticWeights(frequencies)
    return mean(distances, weights)
end

using PyPlot
function main()
    system::Vector{Gaussian} = [
        Gaussian(0.0, .2, "A"),
        Gaussian(.2, .2, "B"),
        Gaussian(.5, .2, "C"),
        Gaussian(.7, .2, "D"),
        Gaussian(.9, .2, "E"),
        Gaussian(.16, .2, "F"),
        Gaussian(.21, .2, "G"),
        Gaussian(.5, .2, "H"),
        Gaussian(.75, .2, "I"),
        Gaussian(1.0, .2, "J"),
        Gaussian(.34, .2, "K"),
        Gaussian(.56, .2, "L"),
        Gaussian(.93, .2, "M"),
        Gaussian(.03, .2, "N"),
        Gaussian(.48, .2, "O"),
        Gaussian(.29, .2, "P"),
        Gaussian(.289, .2, "Q"),
        Gaussian(.49, .2, "R"),
        Gaussian(.22, .2, "S"),
        Gaussian(.61, .2, "T"),
    ]

    system2::Vector{Gaussian} = [
        Gaussian(0.0, .2, "A"),
        Gaussian(.2, .2, "B"),
        Gaussian(.5, .2, "C"),
        Gaussian(.7, .2, "D"),
        Gaussian(.9, .2, "E"),
        Gaussian(.16, .2, "F")
    ]

    disc_data::Vector{Float64} = []
    samp_data::Vector{Float64} = []

    for m in 1:100
        println(m)
        system2[1].mean+=1/100
        current_system = copy(system2)
        #tree::Tree = create_probability_tree(current_system)
        #push!(disc_data, score_probability_tree(tree, data))

        push!(samp_data, rand_samp_score(map(i->i.mean, current_system)))
    end

    #println(graph_data)
    #plot(disc_data)
    plot(samp_data)
    show()
end

#include("optimizers/gradient_descent.jl")
#gradient_descent(vector_score, rand(20))

main()

#println(vector_score([.2,.6,.1,.04,.44,.37]))
