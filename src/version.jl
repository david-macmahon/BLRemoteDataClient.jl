# Version number of current module.  Adapted from
# https://github.com/JuliaDocs/Documenter.jl/blob/c0cfded/src/Documenter.jl#L25-L32
const VERSION = let
    # Project.toml must be one directry above module's .jl file
    project = joinpath(dirname(dirname(pathof(@__MODULE__))), "Project.toml")
    Base.include_dependency(project) # Retrigger precompilation when Project.toml changes
    toml = read(project, String)
    m = match(r"(*ANYCRLF)^version\s*=\s\"(.*)\"$"m, toml)
    VersionNumber(m[1])
end
