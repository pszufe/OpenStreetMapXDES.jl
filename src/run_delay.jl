#functions for running sim with delay on edges

function run_single_iteration!(sim_data::SimData, 
                                λ_ind::Float64,
                                λ_soc::Float64;
                                perturbed::Bool = true)
    sim_clock = DataStructures.PriorityQueue{Int, Float64}()
    for i = 1:length(sim_data.population)        
        sim_clock[i] = departure_time(sim_data.driving_times + sim_data.population[i].expected_driving_times, sim_data.population[i].route) 
    end
    m, n = size(sim_data.map_data.w)
    stats = Stats(m, n)
    traffic_densities = SparseArrays.spzeros(m, n)
    while !isempty(sim_clock)
        id, current_time = DataStructures.peek(sim_clock)
        agent = sim_data.population[id]
        (agent.current_edge != 1) && (traffic_densities[agent.route[agent.current_edge - 1][1], agent.route[agent.current_edge - 1][2]] -= 1.0)
        if agent.current_edge > length(agent.route)
            DataStructures.dequeue!(sim_clock)
            agent.current_edge = 1
        else
            edge0, edge1 = agent.route[agent.current_edge] 
            driving_time = calculate_driving_time(traffic_densities[edge0, edge1], 
                                                sim_data.max_densities[edge0, edge1],
                                                sim_data.map_data.w[edge0, edge1], 
                                                sim_data.velocities[edge0, edge1])   
            update_beliefs!(agent,edge0, edge1, driving_time, λ_ind)
            update_stats!(stats, edge0, edge1, driving_time)
            traffic_densities[edge0, edge1] += 1.0
            agent.current_edge += 1 
            sim_clock[id] += driving_time
        end
    end
    update_routes!(sim_data, stats.avg_driving_times, λ_soc, perturbed)
end


function run_simulation!(sim_data::SimData, 
                                λ_ind::Float64,
                                λ_soc::Float64,
                                iter::Int64;
								perturbed::Bool = true)
    for i = 1:iter
        run_single_iteration!(sim_data, λ_ind, λ_soc, perturbed = perturbed)
    end
end