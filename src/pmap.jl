"""
    pmap(f, c...)

Like `map(f, c...)` except that iterations are performed in parallel
asynchronously.
"""
function pmap(f, c...)
    map(fetch, map(x->Threads.@spawn(f(x)), c...))
end

"""
    pmapreduce(f, op, c...; [init])

Like `mapreduce(f, op, c...; [init])` except that the mapping is performed in
parallel asynchronously.
"""
function pmapreduce(f, op, c...; init=Base._InitialValue())
    mapreduce(fetch, op, map(x->Threads.@spawn(f(x)), c...); init)
end
