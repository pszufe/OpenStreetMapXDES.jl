using Distributed
using OpenStreetMapX
using OpenStreetMapXDES
using Dates
using DataFrames
using StatsBase
using Serialization
using Nanocsv
using SparseArrays

addprocs(4)

@everywhere using Distributed
@everywhere println("Worker ",myid()," at ",pwd())
@everywhere using Pkg
@everywhere Pkg.activate(".")


@everywhere using OpenStreetMapX
@everywhere using OpenStreetMapXDES
@everywhere using Dates
@everywhere using DataFrames
@everywhere using StatsBase
@everywhere using Serialization
@everywhere using Nanocsv
@everywhere using SparseArrays


include("winnipeg_sim_config_constants.jl")
include("winnipeg_data_prep.jl")


datapath = "C:\\Users\\p\\Desktop\\learningsimdata";
path = "C:\\Users\\p\\Desktop\\learning_drivers";

if length(ARGS) > 0
    datapath = ARGS[1]
    if length(ARGS) > 1
       path = ARGS[2]
    else
       path = datapath
    end
end

mapfile = filenames[:osm]


N = 10_000;
iter = 100;
λ_ind = 0.4; #range(0.0, stop = 1.0, step = 0.05);
λ_soc = 0.2; #range(0.0, stop = 1.0, step = 0.05);
l = 5.0;


sweep = collect(Iterators.product( 1:2,
              range(0.0, stop = 1.0, step = 0.05),
              range(0.0, stop = 1.0, step = 0.05)))


flow_data = get_flow_data(datapath,road_levels = Set(1:4));

sim_data = get_sim_data(flow_data,N,l);

#queue
@sync @distributed for ele in sweep
    mode, λ_ind, λ_soc = ele
    sd1 = deepcopy(sim_data)
    if mode % 2 == 1
        run_sim!(sd1, λ_ind, λ_soc, iter; perturbed=false, proc_id=myid())
    else
        run_simulation!(sd1, λ_ind, λ_soc, iter; perturbed=false, proc_id=myid())
    end
end
println("all done")
