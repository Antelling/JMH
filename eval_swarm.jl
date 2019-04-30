function assert_no_duplicates(swarm::Swarm)
    for (i::Int, a::BitList) in enumerate(swarm)
        for (j::Int, b::BitList) in enumerate(swarm)
            @assert (i == j || a != b)
        end
    end
end
