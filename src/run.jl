#auxiliary functions for running simulation

function departure_time(w::AbstractMatrix{Float64}, route::Array{Tuple{Int64,Int64},1})
    isempty(route) ? (driving_time = 0) : (driving_time = sum(w[edge[1],edge[2]] for edge in route))
    return -driving_time
end

function calculate_driving_time(ρ::Float64,
                                ρ_max::Float64,
                                d::Float64,
                                v_max::Float64,
                                V_min::Float64 = 1.0)
    v = (v_max - V_min)* max((1 - ρ/ρ_max),0.0) + V_min
    return d/v
end

function update_stats!(stats::Stats, edge0::Int, edge1::Int, driving_time::Float64)
    stats.cars_count[edge0, edge1] += 1.0
    stats.avg_driving_times[edge0, edge1] += (driving_time - stats.avg_driving_times[edge0, edge1])/stats.cars_count[edge0, edge1]
end

function update_routes!(sim_data::SimData, stats::Stats, 
                        λ_soc::Float64, perturbed::Bool)
     for agent in sim_data.population
        perturbed ? λ = λ_soc : λ = λ_soc * rand(Uniform(0.0,2.0))
        update_beliefs!(agent, stats.avg_driving_times, λ)
		old_route = agent.route
        agent.route = get_route(sim_data.map_data,
                                sim_data.driving_times + agent.expected_driving_times,
                                agent.start_node, agent.fin_node)
		(agent.route != old_route) && (stats.routes_changed += 1) 
    end
end
