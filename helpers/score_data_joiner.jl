function score_data_joiner(score_f::Function, data)
    return function(system)
        return score_f(system, data)
    end
end
