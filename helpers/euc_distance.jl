function euc_distance(x1::Real, y1::Real, x2::Real, y2::Real)::Float64
    inner = (x1 - x2)^2 + (y1 - y2)^2
    outer = sqrt(inner)
    return outer
end
