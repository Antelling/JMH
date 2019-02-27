"""returns a configured TBO instance"""
function TBO_monad(;prob::Bool=true, repair::Bool=false, repair_op::Function=Pass)
    return function(swarm::Swarm, problem::ProblemInstance)
        return TBO(swarm, problem, prob=prob, repair=repair, repair_op=repair_op)
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
function TBO(swarm::Swarm, problem::ProblemInstance; prob::Bool=true, repair::Bool=false, repair_op::Function=Pass)
    n_dimensions = length(problem.objective)

    #first we need to get the mean for each dimension
    means = zeros(n_dimensions)
    for s in swarm
        means .+= s
    end
    means ./= n_dimensions
    if !prob
        medians::Vector{Bool} = [m > .5 for m in means]
        #if the median is true, the average is greater than half
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
    for i in 1:length(swarm)
        if prob
            new_solution = TBO_prob_perturb(swarm[i], best_solution, means)
        else
            new_solution = TBO_med_perturb(swarm[i], best_solution, medians)
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
        if s > score_solution(swarm[i], problem)
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
    return function(swarm::Swarm, problem::ProblemInstance)
        return LBO(swarm, problem, repair=repair, repair_op=repair_op)
    end
end

function LBO(swarm::Swarm, problem::ProblemInstance; repair::Bool=false, repair_op::Function=Pass)
    n_dimensions = length(problem.objective)
    best_score = 0

    #the two learners are meant to be randomly selected
    #but it doesn't say how many times to do that so I'm just going to loop over every s in swarm
    #FIXME: discuss with Vasko. But it seems to work well
    for i in 1:length(swarm)
        #println(i)
        first_learner = swarm[i]

        #over time, the swarm will converge to several identical solutions
        #eventually only one solution will exist
        second_learner_index = rand(1:length(swarm))
        second_learner = swarm[second_learner_index]
        while second_learner == first_learner
            second_learner_index = rand(1:length(swarm))
            second_learner = swarm[second_learner_index]
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
