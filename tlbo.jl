"""returns a configured TBO instance"""
function TBO_monad(;prob::Bool=true, repair::Bool=false, repair_op::Function=Pass)
    return function TBO_mondad_internal(swarm::Swarm, problem::ProblemInstance; verbose::Int=0)
        return TBO(swarm, problem, prob=prob, repair=repair, repair_op=repair_op, verbose=0)
    end
end

"""The TBO algorithm, from the TLBO metaheuristic.
This was also made discrete by replacing any continous range by a sample of
integers from that range. However, TBO also has a 'mean of the average learner'
component. There are two ways to make this component discrete:
take the median: means[i] > .5
treat it as a probability: rand() < means[i]
The method used is controlled by the prob parameter, and defaults to true, since
the probability method seems to work better in the majority of cases. """
function TBO(swarm::Swarm, problem::ProblemInstance; prob::Bool=true, repair::Bool=false, repair_op::Function=Pass, verbose::Int=0)
    n_dimensions = length(problem.objective)

    #first we need to get the mean for each dimension
    if prob
        means = zeros(n_dimensions)
        for s in swarm
            means .+= s
        end
        means ./= n_dimensions
    else
        #the median is the solution with the median objective value
        scores = [(s, score_solution(s, problem)) for s in swarm]
        sort!(scores, by=t->t[2])
        median = scores[Int(round(length(scores)+.1))][1]
    end

    if verbose > 3
        println("mean found: $(means)")
    end

    #now we find the best solution
    best_solution::BitList = []
    best_score = 0
    for solution in swarm
        current_score = score_solution(solution, problem)
        if current_score > best_score
            best_score = current_score
            best_solution = solution
        end
    end

    #now we apply the TBO transformation to each element of the data, and accept the change if the
    #score improves
    if verbose > 3
        println("applying TBO transformation to every element of swarm...")
    end
    for i in 1:length(swarm)
        if prob
            new_solution = TBO_prob_perturb(swarm[i], best_solution, means)
        else
            new_solution = TBO_med_perturb(swarm[i], best_solution, median)
        end

        val = is_valid(new_solution, problem)
        if !val
            if repair
                val, new_solution = repair_op(new_solution, problem)
                if !val
                    continue
                end
            else
                continue
            end
        end
        s = score_solution(new_solution, problem)
        if s > score_solution(swarm[i], problem) && !(new_solution in swarm)
            swarm[i] = new_solution
            if s > best_score
                best_score = s
            end
        end
    end
    return (swarm, best_score)
end

function TBO_prob_perturb(solution::BitList, best_solution::BitList, means::Vector{Float64})
    #this is terrible and unreadable but super fast
    #the rand([1, 2]) is the tf value. Which isn't a parameter just a random number
    #rand() < means[i] is how I made the means[] discrete. It works better than using the median
    return [bit + rand([0,1])*(best_solution[i]-(rand([1, 2]))*(rand() < means[i])) > 0 for (i, bit) in enumerate(solution)]
end

function TBO_med_perturb(solution::BitList, best_solution::BitList, medians::Vector{Bool})
    return [bit + rand([0,1])*(best_solution[i]-(rand([1, 2]))*medians[i]) > 0 for (i, bit) in enumerate(solution)]
end

"""returns a configured LBO instance"""
function LBO_monad(; repair::Bool=false, repair_op::Function=Pass)
    return function LBO_monad_internal(swarm::Swarm, problem::ProblemInstance; verbose::Int=0)
        return LBO(swarm, problem, repair=repair, repair_op=repair_op, verbose=verbose)
    end
end


function LBO(swarm::Swarm, problem::ProblemInstance; repair::Bool=false, repair_op::Function=Pass, verbose::Int=0)
    assert_no_duplicates(swarm)
    n_dimensions = length(problem.objective)
    swarm_len = length(swarm)
    best_score = 0

    if verbose > 3
        println("applying LBO transformation to every element of swarm...")
    end
    for i in 1:swarm_len
        if verbose > 4 println("swarm item $(i) of $(swarm_len)") end
        first_learner = swarm[i]

        second_learner_index = rand(deleteat!(collect(1:swarm_len), i))
        second_learner = swarm[second_learner_index]

        if verbose > 4
            println("different learners selected: $(i) and $(second_learner_index)")
            @assert first_learner != second_learner
        end

        first_learner_score = score_solution(first_learner, problem)
        if first_learner_score > best_score
            best_score = first_learner_score
        end
        second_learner_score = score_solution(second_learner, problem)
        if first_learner_score > second_learner_score
            teacher = first_learner
            student = second_learner
            student_index = second_learner_index
            student_score = second_learner_score
        else
            teacher = second_learner
            student = first_learner
            student_index = i
            student_score = first_learner_score
        end

        if verbose > 4 println("applying bit transformations...") end

        new_student = copy(student)
        for j in 1:n_dimensions
            new_bit = new_student[j] + rand([0,1]) * (teacher[j] - new_student[j])
            new_student[j] = new_bit
        end

        val = is_valid(new_student, problem)
        if !val
            if repair
                val, new_student = repair_op(new_student, problem)
                if !val
                    continue
                end
            else
                continue
            end
        end
        s = score_solution(new_student, problem)
        if s > student_score && !(new_student in swarm)
            swarm[student_index] = new_student
            if s > best_score
                best_score = s
            end
        end
    end

    return (swarm, best_score)
end
