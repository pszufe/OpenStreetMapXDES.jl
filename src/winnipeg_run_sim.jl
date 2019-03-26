using OpenStreetMapX
using OpenStreetMapXDES
using Dates
using DataFrames
using StatsBase
using Serialization
using Nanocsv
using SparseArrays

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
λ_ind = 0.4; #range(0.0, stop = 1.0, step = 0.02);
λ_soc = 0.2; #range(0.0, stop = 1.0, step = 0.02);
l = 5.0;

flow_data = get_flow_data(datapath,road_levels = Set(1:4));

sim_data = get_sim_data(flow_data,N,l);

#queue
sd1 = deepcopy(sim_data)
@info "copy sd1 of sim_data created"
run_sim!(sim_data, λ_ind, λ_soc, iter)

#delay
sd2 = deepcopy(sim_data)
@info "copy sd2 of sim_data created"
run_simulation!(sd2, λ_ind, λ_soc, iter)
