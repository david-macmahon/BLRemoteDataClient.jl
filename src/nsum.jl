"""
    nsum(A, n; dims)

Reduce the dimensions of `A` in `dims` by summing every `n` elements of the
dimensions.  `n` can be an Integer for a single dimension or a Tuple of
Integers.  If `n` is a Tuple, `dims` must also be a Tuple.  If `n` is an
Integer, `dims` may be a same type Integer (each of which get reduced by `n`) or
a `Tuple` of same type Integers.
"""
function nsum(A, n::NTuple{N, T}; dims::NTuple{N, T}) where {N, T<:Integer}
    # Validate input
    sz = size(A)
    for (nn, dd) in zip(n, dims)
        @assert sz[dd] % nn == 0 "dimension $dd is not divisible by $nn"
    end
    reshapedims = Iterators.flatmap(1:ndims(A)) do i
        di = findfirst(==(i), dims)
        di === nothing ? sz[i] : (n[di], sz[i]÷n[di])
    end |> Tuple
    opdims = map(i->i+count(<(i), dims), dims)
    dropdims(sum(reshape(A, reshapedims); dims=opdims); dims=opdims)
end

function nsum(A, n::T; dims) where {T<:Integer}
    nsum(A, ntuple(i->n, length(dims)); dims=Tuple(dims))
end

"""
    nmean(A, n; dims)

Reduce the dimensions of `A` in `dims` by averaging every `n` elements of the
dimensions.  `n` can be an integer for a single dimension or a Tuple of
Integers.  If `n` is a Tuple, `dims` must also be a Tuple.  If `n` is an
Integer, `dims` may be a same type Integer (each of which get reduced by `n`) or
a `Tuple` of same type Integers.
"""
function nmean(A, n::NTuple{N, T}; dims::NTuple{N, T}) where {N, T<:Integer}
    nsum(A, n; dims) ./ prod(n)
end

function nmean(A, n::T; dims) where {T<:Integer}
    nmean(A, ntuple(i->n, length(dims)); dims=Tuple(dims))
end

"""
    nmean(r::AbstractRange, n::Integer)

Return a range whose elements are the mean of every `n` elements of `r`.
"""
function nmean(r::AbstractRange, n::Integer)
    n <= 1 && return r
    @assert length(r) % n == 0 "length of range ($(length(r))) not divisible by $n"
    newfirst = first(r) + (n-1)*step(r)/2
    newstep = n * step(r)
    newlength = length(r) ÷ n
    range(newfirst; step=newstep, length=newlength)
end
