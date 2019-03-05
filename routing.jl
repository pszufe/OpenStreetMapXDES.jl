function get_route(m::OpenStreetMapX.MapData,
    w::AbstractMatrix{T},
    node0::Int64, 
    node1::Int64;
	heuristic::Function = n -> zero(T)) where {T}
    route_indices, route_values = OpenStreetMapX.a_star_algorithm(m.g, node0, node1, w, heuristic)
    [(route_indices[j - 1],route_indices[j]) for j = 2:length(route_indices)]
end