using SparseArrays
using Dates
using OpenStreetMapX
using StatsBase
using Nanocsv
using DataFrames
using Serialization
using Distributions
using LightGraphs
using DataStructures


datapath = "C:\\Users\\p\\Desktop\\learningsimdata";
path = "C:\\Users\\p\\Desktop\\learning_drivers";
mapfile = "Winnipeg CMA.osm";

include(joinpath(path,"types.jl"))
include(joinpath(path,"a_star.jl"))
include(joinpath(path,"routing.jl"))
include(joinpath(path,"create_enviroment.jl"))
include(joinpath(path,"run.jl"))

clock_dist = Normal(1800.0,540.0);
N = 100;
iter = 1;
λ_ind = 0.4;
λ_soc = 0.2;
l = 5.0;

map_data = OpenStreetMapX.get_map_data(datapath, mapfile);
sim_data = get_sim_data(map_data,N,l);
					
@time run_simulation!(sim_data, 
                clock_dist, 
                λ_ind,
                λ_soc,
                iter)
				

