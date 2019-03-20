using Test, OpenStreetMapXDES
import LightGraphs

@testset "maps" begin

m = OpenStreetMapX.get_map_data("data/reno_east3.osm",use_cache=false);

@test length(m.nodes) == 9032

using Random
Random.seed!(0);
sim_data = get_sim_data(m,1000,5.0);
@test sim_data.population[1].start_node == 113
@test sim_data.population[245].fin_node == 1684
@test sim_data.max_densities[1295, 1966] == 10.3915514073505

d1 = deepcopy(sim_data);
d2 =deepcopy(sim_data);
res_delay = run_simulation!(d1, 0.5, 0.5, 5);
res_queue = run_sim!(d2, 0.5, 0.5, 5);
    
@test res_delay[5] == [657, 651, 457, 440, 411]
@test res_queue[2][1] == 0.014469245490726623
    
@test d1.population[1].expected_driving_times[1900,3] == 47.911625308525686
@test d1.population[100].current_edge == 1
@test (d1.population[333].route[1][1],d1.population[333].route[end][2]) == (1383, 1421)

@test d2.population[10].expected_driving_times[1279,5] == 6.52305898147509
@test d2.population[1].current_edge == 1 
@test (d2.population[1000].route[1][1],d2.population[1000].route[end][2]) == (1886, 726)

end;