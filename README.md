# OpenStreetMapXDES.jl

Discrite event simulator for [`OpenStreetMapX.jl`](https://github.com/pszufe/OpenStreetMapX.jl)

The goal of this package is to provide a mechanism for multi-agent simulation of cities. 



| **Documentation** | **Build Status** |
|---------------|--------------|
|[![][docs-latest-img]][docs-dev-url]| [![Build Status][travis-img]][travis-url]  [![Coverage Status][codecov-img]][codecov-url] <br/> Linux and macOS |

## Documentation

- [**DEV**][docs-dev-url] &mdash; **documentation of the development version.**

[docs-latest-img]: https://img.shields.io/badge/docs-latest-blue.svg
[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-dev-url]: https://pszufe.github.io/OpenStreetMapXDES.jl/dev

[travis-img]: https://travis-ci.org/pszufe/OpenStreetMapXDES.jl.svg?branch=master
[travis-url]: https://travis-ci.org/pszufe/OpenStreetMapXDES.jl

[codecov-img]: https://coveralls.io/repos/github/pszufe/OpenStreetMapXDES.jl/badge.svg?branch=master
[codecov-url]: https://coveralls.io/github/pszufe/OpenStreetMapXDES.jl?branch=master

## Installation

The current version uses Julia 1.0

```julia
using Pkg
Pkg.add("OpenStreetMapX")
Pkg.add(PackageSpec(url="https://github.com/pszufe/OpenStreetMapXDES.jl"))
```

Note that on Linux platform you need to separately install `libexpat` used by `OpenStreetMapX`.

## Usage

```julia
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
```
