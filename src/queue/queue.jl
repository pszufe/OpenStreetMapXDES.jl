"""
    update_control_flow!(sim_data::SimData, sim_flow::ControlFlow, edge::Tuple{Int,Int},
                            stats::Stats, id::Int, λ::Float64, current_time::Float64, 
                            waiting_time::Float64 = 0.0)  

Function updating agent and simulation statistics

**Arguments**

* `sim_data`            : SimData object
* `sim_flow`            : ControlFlow object
* `edge`                : Tuple with id of agent's current edge
* `stats`               : Stats object
* `id`                  : agent's id
* `λ`                   : learning rate
* `current_time`        : actual sim clock
* `waiting_time`        : waiting time when agent waits in traffic jam
"""
function update_control_flow!(sim_data::SimData, sim_flow::ControlFlow, edge::Tuple{Int,Int},
                            stats::Stats, id::Int, λ::Float64, current_time::Float64, 
                            waiting_time::Float64 = 0.0)  
    agent = sim_data.population[id]
    driving_time = calculate_driving_time(sim_flow.edges[edge].cars_count, 
                                        sim_data.max_densities[edge],
                                        sim_data.map_data.w[edge], 
                                        sim_data.velocities[edge])    
    update_beliefs!(agent,edge[1], edge[2], driving_time + waiting_time, λ)
    update_stats!(stats, edge[1], edge[2], driving_time + waiting_time)
    sim_flow.edges[edge].cars_count += 1.0
    agent.current_edge += 1 
    sim_flow.sim_clock[id] = current_time + driving_time 
end

"""
    new_route!(sim_data::SimData, agent::Agent, edge::Tuple{Int,Int}) 

This function calculates new route when agent decided 
to change it in order to avoid traffic jam

**Arguments**

* `sim_data`   : SimData object
* `agent`      : Agent object
* `edge`       : Tuple with id of agent's current edge
"""
function new_route!(sim_data::SimData, agent::Agent, edge::Tuple{Int,Int})
    #to later update sim flow add previous edge to agents new route(if needed):
    if agent.current_edge != 1 
        route = [agent.route[agent.current_edge - 1], (edge[1], edge[2]),]
        agent.current_edge = 2
    else
        route = [(edge[1], edge[2]),]
    end
    #select new route:
    agent.route = vcat(route, get_route(sim_data.map_data,
                        sim_data.driving_times + agent.expected_driving_times,
                        edge[2], agent.fin_node))
end

"""
    function update_route!(sim_data::SimData, sim_flow::ControlFlow, 
                          edge::Tuple{Int,Int}, id::Int, time::Float64) 

Function controlling behaviour of agent on the intersection;
He drives by when he is capable to, in other case
he randomly decide to stay in traffic jam or to change
his route to not clogged one (if exist)

**Arguments**

* `sim_data`            : SimData object
* `sim_flow`            : ControlFlow object
* `edge`                : Tuple with id of agent's current edge
* `id`                  : agent's id
* `time`                : sim clock value
"""
function update_route!(sim_data::SimData, sim_flow::ControlFlow, 
                        edge::Tuple{Int,Int}, id::Int, time::Float64)
    agent = sim_data.population[id]
    #if he is capable of moving forward, then do nothing:
    sim_flow.edges[edge].cars_count + 1.0 > max(sim_data.max_densities[edge],1.0) || return true
    #otherwise create a list of feasible roads and select one of them randomly:
    select_route = [edge,]
    for node in sim_data.map_data.g.fadjlist[edge[1]]
        clogged = sim_flow.edges[edge[1],node].cars_count + 1.0 > max(sim_data.max_densities[edge[1],node],1.0) 
        clogged || push!(select_route, (edge[1],node))
    end
    new_edge = rand(select_route)
    #if he has decided to stay on the same route, put him on queue:
    if new_edge == edge
        push!(sim_flow.edges[edge].waiting_queue,(id, time))
        sim_flow.sim_clock[id] = Inf
        return false
    #otherwise find new route:
    else
        new_route!(sim_data, agent, new_edge)
        return true
    end
end  

"""
    update_queue!(sim_data::SimData, sim_flow::ControlFlow, edge::Tuple{Int,Int}, 
                stats::Stats, current_time::Float64, λ::Float64)

Function updating queue on the intersection;
When agent has moved forward we are capable
of moving also other agents waiting to enter
to current edge. If they are capable they will
move with the previously selected route,
otherwise they will randomly change route 
or stay in the queue

**Arguments**

* `sim_data`            : SimData object
* `sim_flow`            : ControlFlow object
* `edge`                : Tuple with id of agent's current edge
* `stats`               : Stats object
* `current_time`        : actual sim clock
* `λ`                   : learning rate
"""
function update_queue!(sim_data::SimData, sim_flow::ControlFlow, edge::Tuple{Int,Int}, 
                        stats::Stats, current_time::Float64, λ::Float64)
    #select first agent waiting in queue:
    id, previous_clock = popfirst!(sim_flow.edges[edge].waiting_queue)
    agent = sim_data.population[id]
    #find if he is capable of moving forward:
    update_route!(sim_data, sim_flow, edge, id, previous_clock) || return false
    #calculate how long he has been waiting:
    waiting_time = current_time - previous_clock
    #if he finish his route, remove him from model:
    #otherwise, update his stats:
    update_control_flow!(sim_data, sim_flow, agent.route[agent.current_edge],
                                stats, id, λ_ind, current_time, waiting_time)  
    #update agent(s) in his previous edge:
    agent.current_edge > 2 && update_previous_edge!(sim_data, sim_flow, agent.route[agent.current_edge - 2], stats, current_time, λ_ind)
    return true
end

"""
    update_previous_edge!(sim_data::SimData, sim_flow::ControlFlow, edge::Tuple{Int,Int}, 
                        stats::Stats, current_time::Float64, λ::Float64)

Function updating previous edge of agent's route

**Arguments**

* `sim_data`            : SimData object
* `sim_flow`            : ControlFlow object
* `edge`                : Tuple with id of agent's current edge
* `stats`               : Stats object
* `current_time`        : actual sim clock
* `λ`                   : learning rate
"""
function update_previous_edge!(sim_data::SimData, sim_flow::ControlFlow, edge::Tuple{Int,Int}, 
                            stats::Stats, current_time::Float64, λ::Float64)
    #remove agent from previous edge:
    sim_flow.edges[edge[1],edge[2]].cars_count -= 1.0
    #check if some agents are waiting to enter this edge and can move to edge:
    while !isempty(sim_flow.edges[edge].waiting_queue)
        !update_queue!(sim_data, sim_flow, edge, stats, current_time, λ) && break
    end
end

"""
    unclog!(sim_data::SimData, sim_flow::ControlFlow,
            stats::Stats, current_time::Float64, λ::Float64)

Special function used in rare cases when whole sim is clogged.
It basically reduce model to model with delay for all agents
who are not capable of moving forward.

**Arguments**

* `sim_data`            : SimData object
* `sim_flow`            : ControlFlow object
* `stats`               : Stats object
* `current_time`        : actual sim clock
* `λ`                   : learning rate
"""
function unclog!(sim_data::SimData, sim_flow::ControlFlow,
                stats::Stats, current_time::Float64, λ::Float64)
    for (edge, edge_traffic) in sim_flow.edges
        while !isempty(edge_traffic.waiting_queue)
            id, previous_clock = popfirst!(sim_flow.edges[edge].waiting_queue)
            agent = sim_data.population[id]
            waiting_time = current_time - previous_clock
            update_control_flow!(sim_data, sim_flow, edge, stats, 
                                id, λ, current_time, waiting_time)  
            agent.current_edge > 2 && update_previous_edge!(sim_data, sim_flow, agent.route[agent.current_edge - 2],
                                                            stats, current_time, λ)
        end
    end
end
