"""
The `EdgeTraffic` represents traffic on the specific route segment

**Fields**

* `cars_count` :  number of cars on the route segment
* `waiting_queue` :  priority queue with cars trying to enter the edge
"""
mutable struct EdgeTraffic
    cars_count::Float64
    waiting_queue::Array{Tuple{Int,Float64}}
end
EdgeTraffic() = EdgeTraffic(0.0,Tuple{Int,Float64}[])

"""
The `ControlFlow` represents traffic on the specific route segment

**Fields**

* `edges` :  mapping edge id to the object of type EdgeTraffic: (edge0, edge1) => EdgeTraffic()
* `sim_clock` :  priority queue controlling simulation flow
"""
mutable struct ControlFlow
    edges::Dict{Tuple{Int,Int},EdgeTraffic}
    sim_clock::DataStructures.PriorityQueue{Int,Float64}
end

"""
    ControlFlow(sim_data::SimData)

Constructor - creates the struct controlling simulation flow:
priority queue with all agents and their departure time
and also the dictionary of all edges mapping edge id to the object of type EdgeTraffic:
(edge0, edge1) => EdgeTraffic()

**Arguments**

* `sim_data` : SimData object
"""
function ControlFlow(sim_data::SimData)
    edges = Dict{Tuple{Int,Int},EdgeTraffic}()
    queue = DataStructures.PriorityQueue{Int,Float64}()
    for (i, agent) in enumerate(sim_data.population)
        queue[i] = departure_time(sim_data.driving_times + agent.expected_driving_times, agent.route)
    end
    for (node0,node1) in sim_data.map_data.e
         edges[(sim_data.map_data.v[node0], sim_data.map_data.v[node1])] = EdgeTraffic()
    end
    ControlFlow(edges,queue)
end