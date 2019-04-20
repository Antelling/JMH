"""Displays statistics about results in results/"""

using JSON
using Statistics: mean, median

const results_dir = "results"

optimals = JSON.parse(read(open("data/optimal.json"), String))

for (i, file) in enumerate(readdir(results_dir))
    if i == 8
        i = 9
    end
    if i == 7
        i = 8
    end
    results = JSON.parse(read(open(joinpath(results_dir, file)), String))
    println("info for ", file)
    alg_results = []
    println("$(length(results["TBO_med_repair"])) entries")
    for (key, values) in results
        times = [b[2] for b in values]
        scores = [(1-(optimals["$(i)"][j]-b[1])/optimals["$(i)"][j])*100 for (j, b) in enumerate(values)]
        push!(alg_results, (key, mean(scores), median(times)))
    end
    sort!(alg_results, by=i->-i[2])
    for r in alg_results
        println("    $(r[1]) averaged $(round(100*r[2])/100)% with a median $(round(100*r[3])/100) seconds per problem")
    end

    readline(stdin)
end
