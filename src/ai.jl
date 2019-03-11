#mutable struct Brain
    #λ_ind::Float64 
    #λ_soc::Int64
    #expected_driving_times::SparseArrays.SparseMatrixCSC{Float64,Int64}
#end

function update_beliefs!(agent::Agent, edge0::Int, edge1::Int,
                        driving_time::Float64, λ::Float64)
    agent.expected_driving_times[edge0, edge1] += λ*(driving_time - agent.expected_driving_times[edge0, edge1])
end

function update_beliefs!(agent::Agent, 
                        driving_times::SparseArrays.SparseMatrixCSC{Float64,Int64},
                        λ::Float64)
    agent.expected_driving_times += λ *(driving_times - agent.expected_driving_times)
end

