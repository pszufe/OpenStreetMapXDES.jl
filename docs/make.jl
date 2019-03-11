using Documenter

try
    using OpenStreetMapXDES
catch
    if !("../src/" in LOAD_PATH)
       push!(LOAD_PATH,"../src/")
       @info "Added \"../src/\"to the path: $LOAD_PATH "
       using OpenStreetMapXDES
    end
end

makedocs(
    sitename = "OpenStreetMapXDES",
    format = format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    ),
    modules = [OpenStreetMapXDES],
    pages = ["index.md", "reference.md"],
    doctest = true
)



deploydocs(
    repo ="github.com/pszufe/OpenStreetMapXDES.jl.git",
    target="build"
)
