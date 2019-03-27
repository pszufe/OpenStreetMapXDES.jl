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
			push!(stats.delays, current_time)
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
    update_routes!(sim_data, stats, λ_soc, perturbed)
	return stats
end


function run_simulation!(sim_data::SimData, 
                                λ_ind::Float64,
                                λ_soc::Float64,
                                iter::Int64;
								perturbed::Bool = true, proc_id=0)
	#mean_driving_times = Float64[]
	#std_driving_times = Float64[]
	#mean_delays = Float64[]
	#std_delays = Float64[]
	#routes_changed = Int[]
    
    fname = "delay_lind_$(λ_ind)_lsoc_$(λ_soc)"
    @info "Opening file $fname"
    file = open(fname, "w")
    println(file, "proc,time,i,type,l_ind,l_soc,mean_driving_times,std_driving_times,mean_delays,std_delays,routes_changed")
    for i = 1:iter
        start_time = time()
        stats = run_single_iteration!(sim_data, λ_ind, λ_soc, perturbed = perturbed)
		filtered_times = filter(x -> !isnan(x) && x != 0, stats.avg_driving_times ./ sim_data.driving_times)		
        println(file,join(
            [proc_id, Int(round(time()-start_time)), i,"D",λ_ind, λ_soc,mean(filtered_times), std(filtered_times), mean(stats.delays),std(stats.delays),stats.routes_changed], ","))
        flush(file)
    end
    close(file)

end