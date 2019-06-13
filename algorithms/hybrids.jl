function ordered_walk_through_algs(algs::Vector{Function}, swarm::Swarm, problem::ProblemInstance;
			verbose::Int=0, n_fails::Int=5)
	for alg in algs
		swarm, current_score = iterate_alg(alg, swarm, problem, n_fails=n_fails)
	end
	return (swarm, find_best_score(swarm, problem))
end

"""returns a configured ordered walk instance"""
function ordered_walk_monad(algs::Vector{Function}; verbose::Int=0, n_fails::Int=5)
	return function ordered_monad(swarm::Swarm, problem::ProblemInstance)
        return ordered_walk_through_algs(algs, swarm, problem, verbose=verbose, n_fails=n_fails)
    end
end

function TLGJ_monad(;prob::Bool=true, repair_op::Function=VSRO)
    return function TBO_mondad_internal(swarm::Swarm, problem::ProblemInstance; verbose::Int=0)
        swarm = TBO(swarm, problem, prob=prob, repair_op=repair_op, verbose=verbose)[1]
        swarm = LBO(swarm, problem, repair_op=repair_op, verbose=verbose)[1]
		swarm = GA(swarm, problem, repair_op=repair_op, verbose=verbose)[1]
		return jaya(swarm, problem, repair_op=repair_op, verbose=verbose)
    end
end

function GJTL_monad(;prob::Bool=true, repair_op::Function=VSRO, local_search::Function=identity)
    return function TBO_mondad_internal(swarm::Swarm, problem::ProblemInstance; verbose::Int=0)
		swarm = GA(swarm, problem, repair_op=repair_op, verbose=verbose, local_search=local_search)[1]
		swarm = jaya(swarm, problem, repair_op=repair_op, verbose=verbose, local_search=local_search)[1]
        swarm = TBO(swarm, problem, prob=prob, repair_op=repair_op, verbose=verbose, local_search=local_search)[1]
        return LBO(swarm, problem, repair_op=repair_op, verbose=verbose, local_search=local_search)
    end
end

function G2JG4TL_monad(;prob::Bool=true, repair_op::Function=VSRO, local_search::Function=identity)
    return function TBO_mondad_internal(swarm::Swarm, problem::ProblemInstance; verbose::Int=0)
		swarm = GA(swarm, problem, repair_op=repair_op, verbose=verbose, local_search=local_search, n_parents=2)[1]
		swarm = jaya(swarm, problem, repair_op=repair_op, verbose=verbose, local_search=local_search)[1]
		swarm = GA(swarm, problem, repair_op=repair_op, verbose=verbose, local_search=local_search, n_parents=4)[1]
        swarm = TBO(swarm, problem, prob=prob, repair_op=repair_op, verbose=verbose, local_search=local_search)[1]
        return LBO(swarm, problem, repair_op=repair_op, verbose=verbose, local_search=local_search)
    end
end

function VND_TLBO_monad(;repair_op::Function=VSRO)
    return function TBO_mondad_internal(swarm::Swarm, problem::ProblemInstance; verbose::Int=0)
		swarm = VND(swarm, problem, repair_op=repair_op, verbose=verbose)[1]
		return TLBO(swarm, problem, repair_op=repair_op, verbose=verbose)
    end
end

function final(swarm::Swarm, problem::ProblemInstance; verbose::Int=0)
	swarm = iterate_monad(TBO_monad(top_n=15, local_search=identity), n_fails=5, time_limit=3)(swarm, problem)[1]
	swarm = iterate_monad(GA_monad(n_parents=3, local_search=identity), n_fails=10, time_limit=6)(swarm, problem)[1]
	swarm = BF_VND(swarm, problem, n_branches=3)[1]
	return iterate_monad(GA_monad(n_parents=2, local_search=VND), n_fails=10, time_limit=6)(swarm, problem)
end
