module BLRemoteDataClient

using HTTP, JSON
import DataStructures: SortedDict

include("version.jl")
include("ordering.jl")

"""
A `Ref` holding the default hostname of the server.  This is initialized to the
value of `ENV["BL_REMOTE_DATA_SERVER_HOST"]` if set, otherwise `"localhost"`,
but users are free to change this at runtime as desired.
"""
const HOST = Ref{String}()

"""
A `Ref` holding the default port of the server.  This is initialized to the
value of `ENV["BL_REMOTE_DATA_SERVER_PORT"]` if set, otherwise `8000`, but users
are free to change this at runtime as desired.
"""
const PORT = Ref{Int}()

function __init__()
    HOST[] = get(ENV, "BL_REMOTE_DATA_SERVER_HOST", "127.0.0.1")
    p = something(
        tryparse(Int, get(ENV, "BL_REMOTE_DATA_SERVER_PORT", "8000")),
        8000
    )
    PORT[] = p
end

"""
    url(path, [host, [port]])

Return the URL of the server using the given `path`, `host`, and `port`.  Note
that `host` and `port` default to `HOST[]` and `PORT[]`, resp., if not given.
"""
function url(path, host=HOST[], port=PORT[])
    "http://$(host):$(port)/$path"
end

function restcall(f::Function, path, host=HOST[], port=PORT[]; kwargs...)
    query = [string(k)=>string(v) for (k,v) in kwargs]
    resp = HTTP.get(url(path, host, port); query)
    if resp.status == HTTP.StatusCodes.OK
        f(resp)
    else
        error("got unexpected status code $(resp.status)")
    end
end

function restcall(path, host=HOST[], port=PORT[]; kwargs...)
    restcall(path, host, port; kwargs...) do resp
        JSON.Parser.parse(String(resp.body);
                          dicttype=SortedDict{String, Any, BLRDOrdering})
    end
end

"""
    version([host, [port]])::String

Return the version of the BLRemoteDataServer server.
"""
function version(host=HOST[], port=PORT[])::String
    restcall("version", host, port)
end

"""
    prefixes([host, [port]])::Vector{String}

Return the list of directory path prefixes that the server serves.
"""
function prefixes(host=HOST[], port=PORT[])::Vector{String}
    restcall("prefixes", host, port)
end

"""
    readdir(dir, [host, [port]]; regex=".", join=true)::Vector{String}

Return the list of directories and files that are in directory `dir`, which must
be in/under one of the directories being served by the server.  `regex` can be
used to limit the results to names that match the regular expression.  Note that
the regular expression is parsed on the server so this just needs to be a String
here.  If `join` is `true`, the default, the names will be prepended with `dir`.
"""
function readdir(dir, host=HOST[], port=PORT[]; regex=".", join=true)::Vector{String}
    restcall("readdir", host, port; dir, regex, join)
end

"""
    finddirs(dir, [host, [port]]; regex=".", join=true)::Vector{String}

Returns a `Vector` of all directories in and recursively under directory `dir`,
which must be in/under one of the directories being served by the server.
`regex` can be used to limit the results to names that match the regular
expression.  Note that the regular expression is parsed on the server so this
just needs to be a String here.  If `join` is `true`, the default, the names
will be prepended with `dir`.
"""
function finddirs(dir, host=HOST[], port=PORT[]; regex=".", join=true)::Vector{String}
    restcall("finddirs", host, port; dir, regex, join)
end

"""
    findfiles(dir, [host=, [port]]; regex=".", join=true)::Vector{String}

Returns a `Vector` of all files in and recursively under directory `dir`, which
must be in/under one of the directories being served by the server.  `regex` can
be used to limit the results to names that match the regular expression.  Note
that the regular expression is parsed on the server so this just needs to be a
String here.  If `join` is `true`, the default, the names will be prepended with
`dir`.
"""
function findfiles(dir, host=HOST[], port=PORT[]; regex=".", join=true)::Vector{String}
    restcall("findfiles", host, port; dir, regex, join)
end

"""
    fbfiles(dir, [host, [port]]; regex="\\.(fil|h5)\$")::Vector{SortedDict{String,Any}}

Finds all files in/under directory `dir` that match `regex` and returns a
`Vector` of dictionaries each containing the header metadata from a
*Filterbank* file plus `hostname` and `filename` fields.  Matching files
that fail to parse as a *Filterbank* file will have dictionaries containing only
these two "extra" fields.

This function works with both *SIGPROC Filterbank* files (typically having a
`.fil` extension) and *Filterbank HDF5* files (typically having a `.h5`
extension).
"""
function fbfiles(dir, host=HOST[], port=PORT[];
                 regex="\\.(fil|h5)\$")::Vector{SortedDict{String,Any,BLRDOrdering}}
    restcall("fbfiles", host, port; dir, regex)
end

"""
    fbdata(fbname, [host, [port]]; chans=:, ifs=:, times=:, dropdims=())::Array{Float32}

Returns an `Array{Float32}` containing data from the server's *Filterbank* file
named `fbname`.  All or some of the data can be requested by passing the desired
indices of the channel, IF, and time axes using the `chans`, `ifs`, and `times`
keyword argument, resp.  Indices may be `Colon` (i.e. `:`), `Integer` (e.g.
`1`), or an `Integer` range (e.g. `1:1024`).  Note that integer indices are
1-based.  The returned `Array` will be 3-dimensional unless the `dropdims`
keyword argument specifies a dimension or dimensions to drop.  `dropdims` can be
an integer or a tuple of integer values to drop multiple dimensions.  Requesting
to drop a dimension that is greater than 1 will result in an error.

This function works with both *SIGPROC Filterbank* files (typically having a
`.fil` extension) and *Filterbank HDF5* files (typically having a `.h5`
extension).
"""
function fbdata(fbname, host=HOST[], port=PORT[]; chans=:, ifs=:, times=:, dropdims=())::Array{Float32}
    restcall("fbdata", host, port; file=fbname, chans, ifs, times) do resp
        ii = findfirst(p->p[1]=="X-dims", resp.headers)
        dims = parse.(Int, split(resp.headers[ii][2] , ",")) |> Tuple
        data = collect(reshape(reinterpret(Float32, resp.body), dims))
        Base.dropdims(data; dims=dropdims)
    end
end

end # module BLRemoteDataClient
