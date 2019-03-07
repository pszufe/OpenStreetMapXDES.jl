function departure_time(w::AbstractMatrix{Float64}, route::Array{Tuple{Int64,Int64},1}) 
    -(1 + rand()* 0.3 - 0.15) * sum(w[edge[1],edge[2]] for edge in route)
end

function calculate_driving_time(ρ::Float64,
                                ρ_max::Float64,
                                d::Float64,
                                v_max::Float64,
                                V_min::Float64 = 1.0)
    v = (v_max - V_min)* max((1 - ρ/ρ_max),0.0) + V_min
    return d/v
end

function run_single_iteration!(sim_data::SimData, 
                                λ_ind::Float64,
                                λ_soc::Float64;
                                perturbed::Bool = true)
    sim_clock = DataStructures.PriorityQueue{Int, Float64}()
    for i = 1:length(sim_data.population)        
        sim_clock[i] = departure_time(sim_data.driving_times + sim_data.population[i].expected_driving_times, sim_data.population[i].route) 
    end
    m, n = size(sim_data.map_data.w)
    traffic_densities = SparseArrays.spzeros(m, n)
    avg_driving_times = SparseArrays.spzeros(m, n)
    car_count = SparseArrays.spzeros(m, n)
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
            agent.expected_driving_times[edge0, edge1] += λ_ind*(driving_time - agent.expected_driving_times[edge0, edge1])
            car_count[edge0, edge1] += 1.0
            avg_driving_times[edge0, edge1] += (driving_time - avg_driving_times[edge0, edge1])/car_count[edge0, edge1]
            traffic_densities[edge0, edge1] += 1.0
            agent.current_edge += 1 
            sim_clock[id] += driving_time
        end
    end
    for agent in sim_data.population
        perturbed ? λ = λ_soc : λ = λ_soc * rand(Uniform(0.0,2.0))
        agent.expected_driving_times += λ *(avg_driving_times - agent.expected_driving_times)
        f(x, B = agent.fin_node, nodes = sim_data.map_data.nodes, vertices = sim_data.vertices_to_nodes) = OpenStreetMapX.get_distance(x,B,nodes,vertices)
        agent.route = get_route(sim_data.map_data,
                                sim_data.driving_times + agent.expected_driving_times,
                                agent.start_node, 
                                agent.fin_node,
                                heuristic = f)
    end
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