using JSON
using Statistics: mean

const results_dir = "results"

for file in readdir(results_dir)
    try
        results = JSON.parse(read(open(joinpath(results_dir, file)), String))
        println("info for ", file)
        for (key, value) in results
            println("    ", round(mean(value)), " ", key)
        end
    catch
        println(file, " is not valid JSON")
    end
end
