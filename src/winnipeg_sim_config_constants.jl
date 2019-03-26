const filenames = Dict{Symbol,Union{String,Array{String,1}}}(
:osm => "Winnipeg CMA.osm",
:flows =>"hw_flows.csv",
:DAs => "df_DA_centroids.csv",
:demo_stats => "df_demostat.csv",
)

const colnames = Dict(
 :DAs => [:DA_ID, :LONGITUDE, :LATITUDE],
 :demo_stats => [:DA_ID, :ECYTRADRIV],
 :flows  => [:DA_home, :DA_work, :FlowVolume]
 )
 
 