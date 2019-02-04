"""First half of TLBO algorithm. """
function TBO(swarm::Swarm, problem::ProblemInstance)
    n_dimensions = length(problem.objective)

    #first we need to get the mean for each dimension
    means = zeros(n_dimensions)
    for s in swarm
        means .+= s
    end
    means ./= n_dimensions
    #means is a list of floats of like .08, .10, .02
    #we want to make means discrete

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
            difference_mean = new_solution[j] + rand()*(best_solution[j]-tf*means[j])
            #print(" ", difference_mean, " ")
            #FIXME: I don't think TBO is meant to produce discrete solutions, because this is
            #giving me a range of values from -.5 to 1. How do I make that discrete? Let's try this:
            new_solution[j] = difference_mean > 1
        end

        if is_valid(new_solution, problem) && score_solution(new_solution, problem) > score_solution(swarm[i], problem)
            swarm[i] = new_solution
        end
    end
    return (swarm, best_score)
end

function LBO(swarm::Swarm, problem::ProblemInstance)
    n_dimensions = length(problem.objective)
    best_score = 0

    #the two learners are meant to be randomly selected
    #but it doesn't say how many times to do that so I'm just going to loop over every s in swarm
    #FIXME: discuss with Vasko. But it seems to work well
    for i in 1:length(swarm)
        first_learner = swarm[i]
        second_learner_index = rand(1:length(swarm))
        second_learner = swarm[second_learner_index]
        while second_learner == first_learner
            second_learner = rand(swarm)
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

        if score_solution(new_student, problem) > student_score
            swarm[student_index] = new_student
        end
    end

    return (swarm, best_score)
end