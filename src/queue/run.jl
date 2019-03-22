"""
    run_once!(sim_data::SimData, λ_ind::Float64,
            λ_soc::Float64; perturbed::Bool = true)

Main function controlling a single iteration of simulation

**Arguments**

* `sim_data`    : SimData object
* `λ_ind`       : individual learning rate
* `λ_soc`       : social learning rate
* `perturbed`   : boolean variable; controls the perturbation of agent's learning
"""
function run_once!(sim_data::SimData, λ_ind::Float64,
                  λ_soc::Float64; perturbed::Bool = true)
    #initialize sim:
    stats = Stats(size(sim_data.map_data.w)[1], size(sim_data.map_data.w)[2])
    sim_flow = ControlFlow(sim_data)
    current_time = -Inf
    #start main loop:
    while !isempty(sim_flow.sim_clock)
        id, time = DataStructures.peek(sim_flow.sim_clock)
        #if no one can move unclog model:
        if time == Inf 
            unclog!(sim_data, sim_flow, stats, current_time, λ_ind)
            continue
        end
        current_time = time
        agent = sim_data.population[id]
        #if agent finish his route, remove him from model:
        if agent.current_edge > length(agent.route)
            agent.current_edge != 1 && update_previous_edge!(sim_data, sim_flow, 
                                                            agent.route[agent.current_edge - 1],
                                                            stats, current_time, λ_ind)
            push!(stats.delays, current_time)
            DataStructures.dequeue!(sim_flow.sim_clock)
            agent.current_edge = 1
        else
            #otherwise, update his stats and move him forward:
            update_route!(sim_data, sim_flow, agent.route[agent.current_edge], id, current_time) || continue
            update_control_flow!(sim_data, sim_flow, agent.route[agent.current_edge],
                                stats, id, λ_ind, current_time)   
            agent.current_edge > 2 && update_previous_edge!(sim_data,sim_flow, 
                                                            agent.route[agent.current_edge - 2],
                                                            stats, current_time, λ_ind)
        end
    end
    update_routes!(sim_data, stats, λ_soc, perturbed)
    return stats
end

"""
    run_sim!(sim_data::SimData, λ_ind::Float64, λ_soc::Float64,
                 iter::Int64; perturbed::Bool = true)

Main function controlling a simulation

**Arguments**

* `sim_data`    : SimData object
* `λ_ind`       : individual learning rate
* `λ_soc`       : social learning rate
* `iter`        : number of iterations
* `perturbed`   : boolean variable; controls the perturbation of agent's learning
"""
function run_sim!(sim_data::SimData, λ_ind::Float64, λ_soc::Float64,
                 iter::Int64; perturbed::Bool = true)
    mean_driving_times = Float64[]
    std_driving_times = Float64[]
    mean_delays = Float64[]
    std_delays = Float64[]
    routes_changed = Int[]
    for i = 1:iter
        stats = run_once!(sim_data, λ_ind, λ_soc, perturbed = perturbed)
        filtered_times = filter(x -> !isnan(x) && x != 0, stats.avg_driving_times ./ sim_data.driving_times)
        push!(mean_driving_times, Statistics.mean(filtered_times))
        push!(std_driving_times, Statistics.std(filtered_times))
        push!(mean_delays, Statistics.mean(stats.delays))
        push!(std_delays, Statistics.std(stats.delays))
        push!(routes_changed,stats.routes_changed)
    end
	filename = "queue_lind_$(λ_ind)_lsoc_$(λ_soc)"
    file = transpose(hcat(mean_driving_times, std_driving_times, mean_delays, std_delays, routes_changed))
    DelimitedFiles.writedlm( "$filename.csv",  file, ',')
end
