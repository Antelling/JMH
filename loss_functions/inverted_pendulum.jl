struct ControlParams
    p::Float64
    i::Float64
    d::Float64
end

struct System
    support::Vector{Float64}
    ball::Vector{Float64}
    vel_x::Float64
    vel_theta::Float64
    DT::Float64
    iterations::Int64
end

function determine_angle(y::Float64, x::Float64)
    n = atan2(y, x) - .5*pi
    if abs(n) > pi
        n = (2*pi - abs(n)) * -1 * sign(n)
    end
    return n
end

function pid_controller(value::Float64, prev_value::Float64, accumulated_error::Float64, params, DT::Float64)
    accumulated_error += value * DT
    deriv = (value-prev_value)/DT

    p_adj = value * params.p
    i_adj = accumulated_error * params.i
    d_adj = deriv * params.d

    return p_adj + i_adj + d_adj, accumulated_error
end

function get_theta_accel(accel_x::Float64, length::Float64, angle::Float64)
    angle *= -1
    return -1 * ((accel_x/length)*cos(angle) + (-9.81/length)*sin(angle))
end

function euler_simulation(system, accel_x::Float64)
    #cairo graphing has an inverted y axis, so we need to invert it back
    ball::Vector{Float64} = [system.ball[1], system.ball[2] * -1]
    support::Vector{Float64} = [system.support[1], system.support[2] * -1]

    #we can't have unlimited acceleration
    max = 5
    accel_x = abs(accel_x) > max ? max * sign(accel_x) : accel_x

    diff = ball - support
    l = sqrt(sum(diff.^2))
    angle = atan2(diff[2], diff[1]) - 1.5*pi

    x = support[1]
    y = support[2]

    vel_x = system.vel_x
    vel_theta = system.vel_theta

    for _ in 0:system.iterations
        accel_angle = get_theta_accel(accel_x, l, angle)
        vel_theta += accel_angle * system.DT
        angle += vel_theta * system.DT

        vel_x += accel_x * system.DT
        x += vel_x * system.DT
    end

    ball = [x + l * sin(angle), -l*cos(angle) + y]
    support = [x, y]

    #we re-invert the y axis for graphing
    ball[2] *= -1
    support[2] *= -1
    return System(support, ball, vel_x, vel_theta, system.DT, system.iterations)
end

function get_acceleration_response(system, prev_system, params, accumulated_error::Float64)
    angles::Vector{Float64} = []
    for support, ball in [[system.support, system.ball], [prev_system.support, prev_system.ball]]
        ball[2] *= -1 #invert they y because the math gets upset otherwise
        support[2] *= -1

        diff = ball - support
        angle = determine_angle(diff[2], diff[1])
        append!(angles, angle)

        ball[2] *= -1 #invert it back because these are in place transformations
        support[2] *= -1
    end
    return pid_controller(angles[1], angles[2], accumulated_error, params, system.DT * system.iterations)
end

function score(params::Vector{Float64})::Float64
    #simulates an inverted pendulum and tries to center the weight above the platform
    #at x=0 as quickly as possible

    #mutable state of the system
    x = 10 #position of the support
    prev_x = x #previous support position
    d_x = 0 #velocity of the support
    theta = .2 #angle of the weight above the support
    prev_theta = theta #previous theta position
    d_theta = .1 #velocity of the weight above the support

    #immutable system state
    const l = 10.0 #length of the arm
    const timestep = .001 #dt in euler integration
    const g = -10.0 #gravity constant
    const max_accel = 5
    const max_d_x = 10

    #state for the pid controllers
    tilt_accum_error = 0.0
    accel_accum_error = 0.0

    #initiate pid controllers
    pid_tilt_params = ControlParams(params[1:3]...)
    pid_accel_params = ControlParams(params[4:end]...)

    #integrate the overall error of the system
    accumulated_error = 0.0

    for _ in 1:2000
        desired_angle, tilt_error = pid_controller(x, prev_x, tilt_accum_error, pid_tilt_params, timestep)
        tilt_accum_error += tilt_error

        adjusted_angle = theta - desired_angle
        desired_accel, accel_error = pid_controller(theta, prev_theta, accel_accum_error, pid_accel_params, timestep)
        accel_accum_error += accel_error

        if (desired_accel > max_accel) desired_accel = max_accel end

        new_d_x = d_x + desired_accel * timestep
        if new_d_x > max_d_x
            desired_accel = (max_d_x - new_d_x)/timestep
            new_d_x = max_d_x
        end

        #now do the part where you calculate theta accel and update everything
        

        diff = system.ball - system.support
        angle = C.determine_angle(-1 * diff[2], diff[1])
        total += abs(angle)
    end
    return total
end
