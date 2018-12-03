function construct_function(range::Number, mean::Number)
    return function(n) rand(n) .* range .+ mean end
end

function doalot(f::Function, n::Int)
    total = 0
    println(n)
    for x in 1:n
        total += f(1)[1]
    end
    return total
end

constructed = construct_function(1, 100)
con2 = construct_function(1, 1)
straight = function(n) rand(n) .* 1 .+ 100 end
