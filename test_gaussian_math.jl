mutable struct Gaussian
    mean::Float64
    stddev::Float64
    bounded_min::Bool
    bounded_max::Bool
    min::Float64
    max::Float64
    name::String
end

function Gaussian(mean, stddev, name="default")
    return Gaussian(mean, stddev, false, false, 0.0, 0.0, name)
end

using Distributions
function calculate_cdf(z, mean=0, stddev=1)
    return 1 - cdf.(Normal(mean, stddev), z)
end

function chance_a_gt_b(a::Gaussian, b::Gaussian)
    if ((!a.bounded_min) || (a.min < b.max)) && ((!b.bounded_max) || (b.max > a.min))
        new_mean = a.mean - b.mean
        new_stddev = sqrt(a.stddev^2 + b.stddev^2)
        return calculate_cdf(0, new_mean, new_stddev)
    else
        println("not allowed: $(a) and $(b)")
        return 0.0
    end
end

function create_probability_tree(system::Vector{Gaussian})
    #first we sort the system by the mean of the variables
    sort!(system, by=i->i.mean)

    #now we need a storage type for the discrete representations
    #a single discrete system is a list of names
    #we also need to store the probability of each system
    #and we have numerous systems, where order does not matter
    #so we need a set of discrete system and probability tuple pairs
    Tree = Vector{Tuple{Vector{String},Float64}}

    #now we need the first tree, which will have just one system with a
    #probability of 1.0
    tree = Tree()
    push!(tree, (map(i->i.name, system), 1.0))

    #now we want to get the 32 most likely changes
    #2^x == 32 when x == 5
    for x in 1:5
        #we find the most likely swap given the current system
        highest_percentage = 0.0
        index_at = 0
        for i in 1:length(system)-1
            swap_chance = chance_a_gt_b(system[i], system[i+1])
            if swap_chance > highest_percentage
                highest_percentage = swap_chance
                index_at = i
            end
        end

        #okay so now we have the most likely swap
        #which either happens or it doesn't, for each system in our set
        new_tree = Tree()
        for (disc_sys, prob) in tree
            #case didn't happen
            push!(new_tree, (disc_sys, prob * (1-highest_percentage)))
            #case did happen
            other_disc_system = copy(disc_sys)
            other_disc_system[index_at], other_disc_system[index_at+1] = other_disc_system[index_at+1], other_disc_system[index_at]
            push!(new_tree, (other_disc_system, prob * highest_percentage))
        end

        #we we have to apply the swap to the continous system
        middle_ground = (system[index_at].mean + system[index_at+1].mean)/2
        system[index_at].bounded_min = true
        system[index_at].min = middle_ground + eps()
        system[index_at+1].bounded_max = true
        system[index_at+1].max = middle_ground - eps()

        #and now we swap it back
        tree = new_tree
    end
    println(tree)
end

system = [
    Gaussian(.1, .2, "A"),
    Gaussian(.2, .2, "B"),
    Gaussian(.5, .2, "C"),
    Gaussian(.7, .2, "D"),
    Gaussian(.9, .2, "E"),
]

create_probability_tree(system)
