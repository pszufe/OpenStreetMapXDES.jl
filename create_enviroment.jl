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
    buffer = Dict{Tuple{Int64,Int64}, Array{Agent,1}}()
    for i = 1:N
        nodes = get_nodes(m)
        if !haskey(buffer,nodes)
            route = get_route(m, w, nodes[1], nodes[2])
            expected_driving_times = SparseArrays.spzeros(size(w)[1], size(w)[2])
            agent = Agent(nodes[1], nodes[2],
                            route,
                            1,
                            expected_driving_times)
            buffer[nodes] = [agent]
        else
            push!(buffer[nodes],deepcopy(buffer[nodes][1]))
        end
    end
    return vcat(collect(values(buffer))...)
end

function get_sim_data(m::OpenStreetMapX.MapData,
                    N::Int64,
					l::Float64,
                    speeds = OpenStreetMapX.SPEED_ROADS_URBAN)::SimData
	vertices_to_nodes = Dict(reverse.(collect(m.v)))
    driving_times = OpenStreetMapX.create_weights_matrix(m, OpenStreetMapX.network_travel_times(m, speeds))
    velocities = OpenStreetMapX.get_velocities(m, speeds)
	max_densities = get_max_densities(m, l)
    agents = create_agents(m, driving_times, N)
    return SimData(m,
					vertices_to_nodes,
                    driving_times,
                    velocities,
					max_densities,
                    agents)
end