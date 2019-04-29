"""Displays statistics about results in results/"""

using JSON
using Statistics: mean, median

const results_dir = "results"

optimals = JSON.parse(read(open("data/optimal.json"), String))

for file in readdir(results_dir)
    i = parse(Int, file[end-5])
    results = JSON.parse(read(open(joinpath(results_dir, file)), String))
    println("info for ", file)
    alg_results = []
    println("$(length(results["TBO_med_repair"])) entries")
    for (key, values) in results
        times = [b[2] for b in values]
        scores = [((optimals["$(i)"][j]-b[1])/optimals["$(i)"][j])*100 for (j, b) in enumerate(values)]
        push!(alg_results, (key, mean(scores), median(times)))
    end
    sort!(alg_results, by=i->i[2])
    for r in alg_results
        println("    $(r[1]) averaged $(round(100*r[2])/100)% with a median $(round(100*r[3])/100) seconds per problem")
    end

    readline(stdin)
end
