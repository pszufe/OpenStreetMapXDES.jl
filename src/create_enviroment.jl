function get_max_densities(m::OpenStreetMapX.MapData,
                            l::Float64)
    roadways_lanes = Dict{Int64,Int64}()
    for roadway in m.roadways
        if !OpenStreetMapX.haslanes(roadway)
            lanes = 1
        else
            lanes = OpenStreetMapX.getlanes(roadway)
        end
        roadways_lanes[roadway.id] = lanes
    end
    segments = OpenStreetMapX.find_segments(m.nodes,m.roadways,m.intersections)
    segments = Dict((m.v[segment.node0],m.v[segment.node1]) => roadways_lanes[segment.parent] for segment in segments)
    lanes_matrix = SparseArrays.sparse(map(x->getfield.(collect(keys(segments)), x), fieldnames(eltype(collect(keys(segments)))))..., 
	collect(values(segments)),
	length(m.v),length(m.v))
    return m.w .* lanes_matrix / l
end

function get_nodes(m::OpenStreetMapX.MapData)
    start_node, fin_node = 0, 0
    while start_node == fin_node
        start_node = m.v[OpenStreetMapX.point_to_nodes(OpenStreetMapX.generate_point_in_bounds(m), m)]
        fin_node = m.v[OpenStreetMapX.point_to_nodes(OpenStreetMapX.generate_point_in_bounds(m), m)]
    end
    return start_node,fin_node
end

function create_agents(m::OpenStreetMapX.MapData,
                        w::SparseArrays.SparseMatrixCSC{Float64,Int64},
                        N::Int64)
    buffer = Dict{Tuple{Int64,Int64}, Vector{Agent}}()
    nodes_list = Tuple{Int64,Int64}[]
    for i = 1:N
        nodes = get_nodes(m)
        if i % 2000 == 0
            @info "$i agents created"
        end
        if !haskey(buffer,nodes)
            route = get_route(m, w, nodes[1], nodes[2])
            expected_driving_times = SparseArrays.spzeros(size(w)[1], size(w)[2])
            agent = Agent(nodes[1], nodes[2],
                            route,
                            1,
                            expected_driving_times)
            buffer[nodes] = [agent]
            push!(nodes_list,nodes)
        else
            push!(buffer[nodes],deepcopy(buffer[nodes][1]))
        end
    end
    return reduce(vcat,[buffer[k] for k in nodes_list])
end

function get_sim_data(m::OpenStreetMapX.MapData,
                    N::Int64,
					l::Float64,
                    speeds = OpenStreetMapX.SPEED_ROADS_URBAN)::SimData
                    
    driving_times = OpenStreetMapX.create_weights_matrix(m, OpenStreetMapX.network_travel_times(m, speeds))
    velocities = OpenStreetMapX.get_velocities(m, speeds)
	max_densities = get_max_densities(m, l)
    agents = create_agents(m, driving_times, N)
    return SimData(m, driving_times, velocities, max_densities, agents)
end


function get_nodes(flow_data::FlowData)
    start_DA, fin_DA = 0, 0
    while fin_DA == start_DA
        w = StatsBase.fweights(collect(values(flow_data.demographic_data)))
        start_DA =  StatsBase.sample(collect(keys(flow_data.demographic_data)), w)
        row = flow_data.flow_dictionary[start_DA]
        column = StatsBase.sample(StatsBase.fweights(flow_data.flow_matrix[row,:]))
        fin_DA = collect(keys(flow_data.flow_dictionary))[something(findfirst(isequal(column), 
                collect(values(flow_data.flow_dictionary))),rand(1:length(flow_data.flow_dictionary)))]  
    end
    start_node = flow_data.map_data.v[flow_data.DAs_to_intersection[start_DA]]
    fin_node = flow_data.map_data.v[flow_data.DAs_to_intersection[fin_DA]]
    return start_node,fin_node
end

function create_agents(flow_data::FlowData,
                        w::SparseArrays.SparseMatrixCSC{Float64,Int64},
                        N::Int64)
                        
    buffer = Dict{Tuple{Int64,Int64}, Vector{Agent}}()
    nodes_list = Tuple{Int64,Int64}[]
                                     
    for i = 1:N
        nodes = get_nodes(flow_data)
        if i % 2000 == 0
            @info "$i agents created"
        end
           
        if !haskey(buffer,nodes)
            route = get_route(flow_data.map_data, w, nodes[1], nodes[2])
            expected_driving_times = SparseArrays.spzeros(size(w)[1],size(w)[2])
            agent = Agent(nodes[1], nodes[2],
                            route,
                            1,
                            expected_driving_times)
            buffer[nodes] = [agent]
            push!(nodes_list,nodes)   
        else
            push!(buffer[nodes],deepcopy(buffer[nodes][1]))
        end
    end
    return reduce(vcat,[buffer[k] for k in nodes_list])
end

function get_sim_data(flow_data::FlowData,
                    N::Int64,
					l::Float64,
                    speeds = OpenStreetMapX.SPEED_ROADS_URBAN)::SimData
                    
    driving_times = OpenStreetMapX.create_weights_matrix(flow_data.map_data,OpenStreetMapX.network_travel_times(flow_data.map_data, speeds))
    velocities = OpenStreetMapX.get_velocities(flow_data.map_data, speeds)
	max_densities = get_max_densities(flow_data.map_data,l)
    agents = create_agents(flow_data,driving_times,N)
    return SimData(flow_data.map_data,
                    driving_times,
                    velocities,
					max_densities,
                    agents)
end