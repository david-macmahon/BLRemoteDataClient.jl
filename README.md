# BLRemoteDataClient

The *Breakthrough Listen Remote Data Client* provides convenient access to
servers providing a RESTful web based interface to Breakthrough Listen data
stored on the hosts on which the servers run.  A companion project,
[BLRemoteDataServer.jl](
https://github.com/david-macmahon/BLRemoteDataServer.jl) is a Julia package that
provides such a service.

## Installation

In the Julia REPL, run:

```julia
import Pkg
Pkg.add("https://github.com/david-macmahon/BLRemoteDataClient.jl")
```

## Client overview

The client provides functions to access to the following RESTful API endpoints:

| Endpoint  | Function  |
|:----------|:----------|
|/version   | version   |
|/prefixes  | prefixes  |
|/readdir   | readdir   |
|/finddirs  | finddirs  |
|/findfiles | findfiles |
|/fbfiles   | fbfiles   |
|/fbdata    | fbdata    |

Each function takes any required parameters of the endpoint (usually a directory
or file name) as the initial arguments, followed by optional `host` and `port`
arguments, followed by optional keyword arguments corresponding to the optional
endpoint parameters.

The `host` and `port` arguments specify the host and port of the server to
query.  If unspecified, these arguments default to the contents of `HOST` and
`PORT` module variables.  These are `Ref`s whose values can be changed at
runtime if desired.  `HOST` and `PORT` are initialized to the value of the
`BL_REMOTE_DATA_SERVER_HOST` and `BL_REMOTE_DATA_SERVER_PORT` environment
variables, resp.  If an environment variable is not defined, `HOST` is
initialized to `"localhost"` and `PORT` is initialized to 8000.

### Method signatures

Here are the methods supported by the client:

```
version([host, [port]])::String
prefixes([host, [port]])::Vector{String}
readdir(dir, [host, [port]]; regex=".", join=true)::Vector{String}
finddirs(dir, [host, [port]]; regex=".", join=true)::Vector{String}
findfiles(dir, [host, [port]]; regex=".", join=true)::Vector{String}
fbfiles(dir, [host, [port]]; regex="\\.(fil|h5)\$")::Vector{Dict{String,Any}}
fbdata(fbname, [host, [port]]; chans=:, ifs=:, times=:, dropdims=())::Array{Float32}
```

See the doc string of each function for detailed usage.

## Using the client with a single server

To use the client with a single server you can pass the hostname and port of the
server on each call to a client function OR you can store the server's hostname
and port in the `HOST` and `PORT` variables.  Because they are `Ref`s you must
index them with `[]` when getting or setting their value.  The following are
equivalent:

```julia
# With explicit hostname
julia> println(BLRemoteDataClient.prefixes("blc43"))
["/datax", "/datax2", "/datax3"]

# With custom "default" hostname
julia> BLRemoteDataClient.HOST[] = "blc43"
"blc43"

julia> println(BLRemoteDataClient.prefixes())
["/datax", "/datax2", "/datax3"]
```

## Using the client with multiple servers

Julia's broadcasting mechanism provides a convenient way to query multiple hosts
with one call:

```julia
hosts = ["blc$i$j" for i in 0:7 for j in 0:7] # "blc00" to "blc77" 
all_session_dirs = finddirs.("/datax/dibas", hosts; regex="AGBT..._999")
```

When querying many servers it may be beneficial to parallelize the queries by
broadcasting `fetch` over a `Threads.@spawn` generator:

```julia
all_session_dirs = fetch.(Threads.@spawn BLRemoteDataClient.finddirs("/datax/dibas", h, regex="AGBT..._999") for h in hosts)
```
