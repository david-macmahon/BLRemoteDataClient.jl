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

The client provides functions to access to the following RESTful API endpoints
of a `BLRemoteDataServer`:

| Endpoint     | Function    |
|:-------------|:------------|
| /version     | version     |
| /prefixes    | prefixes    |
| /readdir     | readdir     |
| /finddirs    | finddirs    |
| /findfiles   | findfiles   |
| /fbfiles     | fbfiles     |
| /fbdata      | fbdata      |
| /hitsfiles   | hitsfiles   |
| /hitsdata    | hitsdata    |
| /stampsfiles | stampsfiles |
| /stampsdata  | stampsdata  |

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
version([HOST, [port]])::String
prefixes([HOST, [port]])::Vector{String}
readdir(dir, [HOST, [port]]; regex=".", join=true)::Vector{String}
finddirs(dir, [HOST, [port]]; regex=".", join=true)::Vector{String}
findfiles(dir, [HOST, [port]]; regex=".", join=true)::Vector{String}
fbfiles(dir, [HOST, [port]]; regex="\\.(fil|h5)\$")::Vector{SortedDict{String,Any}}
fbdata(FILENAME, [HOST, [port]]; chans=:, ifs=:, times=:, fqav=1, tmav=1, dropdims=())::Array{Float32}
hitsfiles(dir, [HOST, [port]]; regex="\\.hits\$", withdata=false)::Tuple{Vector{SortedDict{String,Any}},Union{Nothing,Vector{Matrix{Float32}}}}
hitsdata(FILENAME, FILEINDEX, [HOST, [port]])::Matrix{Float32}
stampsfiles(dir, [HOST, [port]]; regex="\\.stamps\$")::Vector{SortedDict{String,Any}}
stampsdata(FILENAME, FILEINDEX, [HOST, [port]])::Matrix{Float32}
```

Arguments shown in uppercase can be given as scalars (i.e. single values) or as
Vectors.  When using the Vector forms, all vector-capable arguments must be
given as Vectors.  The queries are run in parallel on the specified hosts and
the results are generally returned as a Vector of the return type shown where
the elements correspond one to one with the Vector arguments passed.  The
exceptions to this are the functions returning `Vector{SortedDict}` which simply
concatenate all the results into a single Vector since the `SortedDict`s contain
the hostname and any other relevant info needed to disambiguate.

See the doc string of each function for detailed usage.

## Using the client with a single server

To use the client with a single server you can pass the hostname and port of the
server on each call to a client function OR you can store the server's hostname
and port in the `HOST` and `PORT` variables of the `BLRemoteDataClient` module.
Because they are `Ref`s you must index them with `[]` when getting or setting
their value.  The following are equivalent:

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

When using the client with multiple servers it is preferable NOT to use
broadcasting because the forms of the functions that take a Vector of hostnames
(and possibly other arguments) will execute the queries in parallel whereas
broadcasting will NOT execute the queries in parallel.
