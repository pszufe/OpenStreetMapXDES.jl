using OpenStreetMapX
using OpenStreetMapXDES


datapath = "C:\\Users\\p\\Desktop\\learningsimdata";
path = "C:\\Users\\p\\Desktop\\learning_drivers";
mapfile = "Winnipeg CMA.osm";



N = 100;
iter = 1;
λ_ind = 0.4;
λ_soc = 0.2;
l = 5.0;

map_data = OpenStreetMapX.get_map_data(datapath, mapfile);
sim_data = get_sim_data(map_data,N,l);

@time run_simulation!(sim_data,
                λ_ind,
                λ_soc,
                iter)
