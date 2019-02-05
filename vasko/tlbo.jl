"""First half of TLBO algorithm. """
function TBO_prob(swarm::Swarm, problem::ProblemInstance; repair=false)
    n_dimensions = length(problem.objective)

    #first we need to get the mean for each dimension
    means = zeros(n_dimensions)
    for s in swarm
        means .+= s
    end
    means ./= n_dimensions

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
        new_solution = copy(swarm[i])

        tf = rand([1, 2]) #this is just some random param that is chosen for each learner

        for j in 1:n_dimensions
            m = rand() < means[j]
            difference_mean = new_solution[j] + rand([0,1])*(best_solution[j]-tf*m)
            new_solution[j] = difference_mean > 0
        end

        valid = false
        if repair && !is_valid(new_solution, problem)
            valid, new_solution = repair_op(new_solution, problem)
        end
        if (valid || is_valid(new_solution, problem)) && score_solution(new_solution, problem) > score_solution(swarm[i], problem)
            swarm[i] = new_solution
        end
    end
    return (swarm, best_score)
end

"""uses the Vasko and Lu median method instead of my probability method"""
function TBO_prob(swarm::Swarm, problem::ProblemInstance; repair=false)
    n_dimensions = length(problem.objective)

    #first we need to get the mean for each dimension
    means::Vector{Float64} = zeros(n_dimensions)
    for s in swarm
        means .+= s
    end
    means ./= n_dimensions
    #the if the median is true, the mean will be > .5
    medians::Vector{Bool} = [m > .5 for m in means]

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
        new_solution = copy(swarm[i])

        tf = rand([1, 2]) #this is just some random param that is chosen for each learner

        for j in 1:n_dimensions
            difference_mean = new_solution[j] + rand([0,1])*(best_solution[j]-tf*medians[j])
            new_solution[j] = difference_mean > 0
        end

        valid = false
        if repair && !is_valid(new_solution, problem)
            valid, new_solution = repair_op(new_solution, problem)
        end
        if (valid || is_valid(new_solution, problem)) && score_solution(new_solution, problem) > score_solution(swarm[i], problem)
            swarm[i] = new_solution
        end
    end
    return (swarm, best_score)
end

function LBO(swarm::Swarm, problem::ProblemInstance; repair=false)
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

        valid = false
        if repair && !is_valid(new_student, problem)
            valid, new_student = repair_op(new_student, problem)
        end
        if score_solution(new_student, problem) > student_score && (valid || is_valid(new_student, problem)) && !(new_student in swarm)
            swarm[student_index] = new_student
        end
    end

    return (swarm, best_score)
end