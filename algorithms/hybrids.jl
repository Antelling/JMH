function pogo_hybrid(algs::Vector{Function}, swarm::Swarm, problem::ProblemInstance;
			verbose::Int=0, n_fails::Int=5, time_limit::Int=60)
	n_algs = length(algs)
	tl = Int(round(time_limit/n_algs))
	for alg in algs
		swarm, current_score = iterate_alg(alg, swarm, problem, n_fails=n_fails, time_limit=tl)
	end
	return (swarm, find_best_score(swarm, problem))
end

function pogo_monad(algs::Vector{Function}; verbose::Int=0, n_fails::Int=5, time_limit::Int=60)
	return function pogo_monad(swarm::Swarm, problem::ProblemInstance)
        return pogo_hybrid(algs, swarm, problem, verbose=verbose, n_fails=n_fails, time_limit=time_limit)
    end
end

function skate_hybrid(algs::Vector{Function}, swarm::Swarm, problem::ProblemInstance;
			verbose::Int=0, n_fails::Int=5, time_limit::Int=60)
	cont = true
	improvement_points = ImprovementPoints()
	start_time = time()
	while cont
		for alg in algs
			if time() - start_time > time_limit
				cont = false
				break
			end
			tries = length(improvement_points) > 0 ? improvement_points[end][1] : 0
			swarm, current_score, local_improvement_points = alg(swarm, problem, verbose=verbose-1)
			local_improvement_points = [(lip[1], lip[2] + tries, lip[3]) for lip in local_improvement_points]
			append!(improvement_points, local_improvement_points)
		end
	end
	return (swarm, find_best_score(swarm, problem), improvement_points)
end

function skate_monad(algs::Vector{Function}; verbose::Int=0, n_fails::Int=5, time_limit::Int=60)
	return function skate_monad_internal(swarm::Swarm, problem::ProblemInstance)
        a, b, c = skate_hybrid(algs, swarm, problem, verbose=verbose, n_fails=n_fails, time_limit=time_limit)
		return (a, b, c)
    end
end

function ordered_applicator_monad(algs::Vector)
	return function ordered_applicator(swarm::Swarm, problem::ProblemInstance)
		best = 0
		improvement_points = ImprovementPoints()
		tries = 0
        for alg in algs
			tries = length(improvement_points) > 0 ? improvement_points[end][1] : 0
			swarm, best, local_improvement_points = alg(swarm, problem)
			local_improvement_points = [(lip[1], lip[2] + tries, lip[3]) for lip in local_improvement_points]
			append!(improvement_points, local_improvement_points)
		end
		return (swarm, best, improvement_points)
    end
end
