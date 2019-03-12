mutable struct Agent
    start_node::Int64 
    fin_node::Int64
    route::Array{Tuple{Int64,Int64},1}
    current_edge::Int64
    expected_driving_times::SparseArrays.SparseMatrixCSC{Float64,Int64}
end

mutable struct SimData
    map_data::OpenStreetMapX.MapData
	vertices_to_nodes::Dict{Int64,Int64} 
	driving_times::SparseArrays.SparseMatrixCSC{Float64,Int64}
	velocities::SparseArrays.SparseMatrixCSC{Float64,Int64}
	max_densities::SparseArrays.SparseMatrixCSC{Float64,Int64}
	population::Array{Agent,1}
end

mutable struct Stats
	routes_changed::Int
	delays::Array{Float64,1}
    cars_count::SparseArrays.SparseMatrixCSC{Float64,Int64}
    avg_driving_times::SparseArrays.SparseMatrixCSC{Float64,Int64}
end

Stats(m::Int,n::Int) = Stats(0, Float64[], SparseArrays.spzeros(m, n), SparseArrays.spzeros(m, n))