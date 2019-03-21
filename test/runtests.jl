using Test
using OpenStreetMapX, OpenStreetMapXDES
import LightGraphs

@testset "maps" begin

m = OpenStreetMapX.get_map_data("data/reno_east3.osm",use_cache=false);

@test length(m.nodes) == 9032

using Random
Random.seed!(0);
@test rand(Int) == -4635026124992869592

sim_data = get_sim_data(m,500,5.0);
@test sim_data.population[1].start_node == 259 
@test sim_data.population[245].fin_node == 1879 
@test sim_data.max_densities[4, 3] == 121.93027174916324

d1 = deepcopy(sim_data);
d2 =deepcopy(sim_data);
res_delay = run_simulation!(d1, 0.5, 0.5, 5);
res_queue = run_sim!(d2, 0.5, 0.5, 5);
    
@test res_delay[5] == [346, 346, 281, 287, 266]
@test res_queue[2][1] == 0.010399885309058353
    
@test d1.population[1].expected_driving_times[1879, 1959] == 24.720806216415745
@test d1.population[100].current_edge == 1
@test (d1.population[333].route[1][1],d1.population[333].route[end][2]) == (604, 1390)

@test d2.population[10].expected_driving_times[9,10] == 5.905046481211313
@test d2.population[1].current_edge == 1 
@test (d2.population[400].route[1][1],d2.population[400].route[end][2]) == (225, 1028)

end;