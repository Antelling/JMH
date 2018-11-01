function euc_distance(x1::Number, y1::Number, x2::Number, y2::Number)::Float64
    return sqrt((x1 - x2)^2 + (y1 - y2)^2)
end