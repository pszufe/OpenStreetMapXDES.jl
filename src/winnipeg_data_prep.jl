#finding closest network node for each DA
"""
Read a csv file with informations about DAs and then for each DA find the nearest route network node.

**Arguments**
* `datapath` : path with csv files
* `filename` : name of csv file
* `colnames` : an array of columns which must be included in each file
* `map_data` : a `OpenStreetMapX.MapData` object
"""
function DAs_to_nodes(datapath::String, filename::String,
                    colnames::Array{Symbol,1},
                    map_data::OpenStreetMapX.MapData)
    DAframe = Nanocsv.read_csv(joinpath(datapath,filename))
	  #DataFrame(CSVFiles.load(joinpath(datapath,filename)))
    if !all(in(col, DataFrames.names(DAframe)) for col in colnames)
        error("Wrong column names! Data Frame should contain $(String.(colnames).*" "... ) columns!")
    end
    DAs_to_nodes = Dict{Int,Int}()
    sizehint!(DAs_to_nodes,DataFrames.nrow(DAframe))
    for i = 1:DataFrames.nrow(DAframe)
        coords = OpenStreetMapX.ENU(OpenStreetMapX.LLA(DAframe[:LATITUDE][i], DAframe[:LONGITUDE][i]), OpenStreetMapX.center(map_data.bounds))
        DAs_to_nodes[DAframe[:DA_ID][i]] = OpenStreetMapX.nearest_node(map_data.nodes,coords,Set(keys(map_data.v)))
    end
    return DAs_to_nodes
end

"""
Include demographic data

**Arguments**
* `datapath` : path with csv files
* `filename` : name of csv file
* `colnames` : an array of columns which must be included in each file
"""
function get_demographic_data(datapath::String, filename::String, colnames::Array{Symbol,1})::Dict{Int,Int}

    demostats = Nanocsv.read_csv(joinpath(datapath,filename))
	    #DataFrame(CSVFiles.load(joinpath(datapath,filename)))
    dfcolnames = names(demostats)
    for col in colnames
        in(col, dfcolnames) || error("Wrong column names! DataFrame demostats does not contain $col")
    end
    demostats = demostats[colnames]
    return Dict(demostats[:DA_ID].=>demostats[:ECYTRADRIV])
end

"""
Include csv file with flow data and create a flow matrix

**Arguments**
* `datapath` : path with csv files
* `filename` : name of csv file
* `colnames` : an array of columns which must be included in each file
"""
function get_flow_data(datapath::String, filename::String, colnames::Array{Symbol,1})
    @info "loading $(joinpath(datapath,filename))"
    flows = Nanocsv.read_csv(joinpath(datapath,filename))
    if !all(in(col, DataFrames.names(flows)) for col in colnames)
        error("Wrong column names! Data Frame should contain $(String.(colnames).*" "... ) columns!")
    end
    flows = flows[colnames]
    vals = unique(vcat(flows[:DA_home],flows[:DA_work]))
    flow_dictionary =  Dict(vals[i] => i for i = 1:length(vals))
    flow_matrix = sparse([flow_dictionary[val] for  val in flows[:DA_home]],[flow_dictionary[val] for  val in flows[:DA_work]],flows[:FlowVolume])
    return flow_dictionary, flow_matrix
end

function elapsed(startt::Dates.DateTime)::Int
    Int(round((Dates.now()-startt).value/1000))
end

function get_flow_data(datapath::String,cachename::Union{String,Nothing}=nothing;
                    road_levels::Set{Int} = Set(1:length(OpenStreetMapX.ROAD_CLASSES)),
                    use_cache::Bool = true)::FlowData
    if cachename == nothing
        cachename = basename(datapath) * "_Data"
    end
    cachefile = joinpath(datapath,cachename*".cache")
    if use_cache && isfile(cachefile)
        f=open(cachefile,"r");
        res=Serialization.deserialize(f);
        close(f);
        @info "Read raw data from cache $cachefile"
    else
        startt = Dates.now()
        files = collect(values(filenames))
        files = vcat(files...)
        files_in_dir = Set(readdir(datapath))
        found_error = false
        for filename in files
            if !in(filename, files_in_dir) 
                @error "The file $filename is missing in the directory $datapath"
                found_error = true
            end
        end
        found_error && error("Some file(s) not found in $datapath")
        @info "All config files found [$(elapsed(startt))s]"
        mapfile = filenames[:osm]
        map_data = OpenStreetMapX.get_map_data(datapath, mapfile; road_levels = road_levels)
        @info "Got map_data( data [$(elapsed(startt))s]"
        DAs_data = filenames[:DAs]
        DAs_to_intersection = DAs_to_nodes(datapath, DAs_data, colnames[:DAs], map_data)
        @info "Got DAs_to_nodes data [$(elapsed(startt))s]"
        demo_stats = filenames[:demo_stats]
        demographic_data = get_demographic_data(datapath, demo_stats, colnames[:demo_stats])
        @info "Got demo_stats data [$(elapsed(startt))s]"
        flow_stats = filenames[:flows]
        flow_dictionary, flow_matrix = get_flow_data(datapath,flow_stats, colnames[:flows])
        @info "Got flow_matrix data [$(elapsed(startt))s]"
        res = FlowData(map_data,
                    DAs_to_intersection,
                    demographic_data,
                    flow_dictionary,
                    flow_matrix)
        if use_cache
            f=open(cachefile,"w");
            Serialization.serialize(f,res);
            @info "Saved raw data to cache $cachefile"
            close(f);
        end
    end
    return res
end

