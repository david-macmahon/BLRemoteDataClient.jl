"""
    pmap(f, A)

Like `map(f, A)` except that iterations are performed in parallel
asynchronously.
"""
function pmap(f, A)
    map(fetch, map(x->Threads.@spawn(f(x)), A))
end

"""
    pmapreduce(f, op, A; [init])

Like `mapreduce(f, op, A; [init])` except that the mapping is performed in
parallel asynchronously.
"""
function pmapreduce(f, op, A; init=Base._InitialValue())
    mapreduce(fetch, op, map(x->Threads.@spawn(f(x)), A); init)
end
