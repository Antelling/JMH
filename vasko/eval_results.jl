using JSON
using Statistics: mean, median

const results_dir = "results"

for file in readdir(results_dir)
    results = JSON.parse(read(open(joinpath(results_dir, file)), String))
    println("info for ", file)
    alg_results = []
    for (key, values) in results
        times = [b[2] for b in values]
        scores = [b[1] for b in values]
        push!(alg_results, (key, mean(scores), median(times)))
    end
    sort!(alg_results, by=i->-i[2])
    for r in alg_results
        println("    $(r[1]) scored $(r[2]) in $(r[3]) seconds")
    end

    for i in 1:length(results["TBO_med_repair"])
        values::Vector{Int} = []
        for (key, scores) in results
            push!(values, scores[i][1])
        end
        print(max(values...), ", ")
    end

    readline(stdin)
end
