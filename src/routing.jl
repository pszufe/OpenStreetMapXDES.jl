function get_route(m::OpenStreetMapX.MapData, w::AbstractMatrix{Float64}, node0::Int64,  node1::Int64)
    f(x, B = agent.fin_node, nodes = m.nodes, vertices = m.n) = OpenStreetMapX.get_distance(x,B,nodes,vertices)/(maximum(values(OpenStreetMapX.SPEED_ROADS_URBAN))/3.6)
    route_indices, route_values = OpenStreetMapX.a_star_algorithm(m.g, node0, node1, w, f)
    [(route_indices[j - 1],route_indices[j]) for j = 2:length(route_indices)]
end