const n_params = 100

const cities = [
 [28, 31],
 [47, 7] ,
 [13, 27],
 [7, 41] ,
 [2, 9]  ,
 [6, 7]  ,
 [8, 1]  ,
 [18, 30],
 [36, 27],
 [13, 25],
 [3, 4]  ,
 [11, 16],
 [41, 25],
 [40, 13],
 [16, 33],
 [12, 31],
 [13, 13],
 [15, 16],
 [8, 38] ,
 [49, 42],
 [19, 14],
 [45, 31],
 [48, 30],
 [40, 39],
 [29, 43],
 [12, 28],
 [47, 24],
 [1, 18] ,
 [8, 26] ,
 [48, 18],
 [22, 35],
 [14, 41],
 [44, 26],
 [8, 34] ,
 [32, 27],
 [42, 6] ,
 [23, 4] ,
 [14, 7] ,
 [45, 48],
 [4, 11] ,
 [11, 46],
 [10, 25],
 [27, 48],
 [4, 14] ,
 [24, 34],
 [10, 22],
 [39, 6] ,
 [27, 34],
 [6, 42] ,
 [9, 46] ,
 [2, 43] ,
 [40, 38],
 [18, 50],
 [12, 34],
 [32, 14],
 [5, 27] ,
 [42, 29],
 [29, 42],
 [19, 21],
 [41, 4] ,
 [10, 4] ,
 [11, 33],
 [19, 40],
 [20, 27],
 [43, 6] ,
 [17, 42],
 [22, 22],
 [17, 30],
 [26, 36],
 [30, 2] ,
 [50, 7] ,
 [36, 17],
 [20, 49],
 [6, 2]  ,
 [36, 35],
 [33, 39],
 [34, 12],
 [18, 17],
 [23, 26],
 [33, 5] ,
 [49, 18],
 [12, 27],
 [34, 43],
 [49, 1] ,
 [39, 5] ,
 [11, 35],
 [39, 25],
 [33, 34],
 [1, 29] ,
 [30, 50],
 [10, 3] ,
 [50, 42],
 [41, 22],
 [22, 6] ,
 [20, 31],
 [44, 46],
 [33, 1] ,
 [47, 9] ,
 [6, 24] ,
 [43, 40]
]

function score(params::Vector{Float64})
    sorted_cities = sort(cities, by=i->params[i])
    total = 0.0
    for i in 1:length(sorted_cities) - 1
        total += euc_distance(sorted_cities[i]..., sorted_cities[i + 1]...)
    end
    return(total)
end
