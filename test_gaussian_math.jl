mutable struct Gaussian
    mean::Float64
    stddev::Float64
    bounded_min::Bool
    bounded_max::Bool
    min::Float64
    max::Float64
end

function Gaussian(mean, stddev)
    return Gaussian(mean, stddev, false, false, 0.0, 0.0)
end

function standard_pdf(z)
    base_value = 1/sqrt(2*pi)
    exp_value = (z^2)/2
    return base_value * exp(-exp_value)
end

using Distributions
function cheater_pdf(z, mean=0, stddev=1)
    return pdf.(Normal(mean, stddev), z)
end

function cheater_cdf(z, mean=0, stddev=1)
    return 1 - cdf.(Normal(mean, stddev), z)
end

function integral_of_normal(z)

end

function chance_a_gt_b(a::Gaussian, b::Gaussian)
    new_mean = a.mean - b.mean
    new_stddev = sqrt(a.stddev^2 + b.stddev^2)
    println(new_mean, new_stddev)
    return cheater_cdf(0, new_mean, new_stddev)
end

#using PyPlot
function simulate(a::Normal, b::Normal)
    bigger = 0
    smaller = 0
    a_samples = rand(a, 1000000)
    b_samples = rand(b, 1000000)
    diffs = a_samples .- b_samples
    #plt[:hist](diffs, 100)
    #show()
    for d in diffs
        if d > 0
            bigger += 1
        else
            smaller += 1
        end
    end
    return bigger/1000000
end

println(simulate(Normal(-5, 3), Normal(1, 2)))

println(chance_a_gt_b(Gaussian(-5, 3), Gaussian(1, 2)))
