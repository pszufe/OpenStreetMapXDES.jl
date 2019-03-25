using OpenStreetMapX
using OpenStreetMapXDES


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

println("Using datapath and path:", datapath, path)
mapfile = "Winnipeg CMA.osm";



N = 10_000;
iter = 1_000;
λ_ind = 0.4;
λ_soc = 0.2;
l = 5.0;

map_data = OpenStreetMapX.get_map_data(datapath, mapfile; road_levels = Set(1:4));
sim_data = get_sim_data(map_data,N,l);

println("run_simulation!...")
@time res_d = run_simulation!(sim_data, λ_ind, λ_soc, iter)

@time res_q = run_sim!(sim_data, λ_ind, λ_soc, iter)
