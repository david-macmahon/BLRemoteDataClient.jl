# Defines a BLRDOrdering type that sorts "data", "fileindex", "hostname", and
# "filename" to the end.

using Base: Ordering, Forward
import Base: lt
import DataStructures: SortedDict

struct BLRDOrdering <: Ordering
end

const BLRDOrder = BLRDOrdering()

function lt(::BLRDOrdering, a, b)
    a == "filename"  ? false :
    b == "filename"  ? true  :
    a == "hostname"  ? false :
    b == "hostname"  ? true  :
    a == "fileindex" ? false :
    b == "fileindex" ? true  :
    a == "data"      ? false :
    b == "data"      ? true  :
    lt(Forward, a, b)
end

function SortedDict{String, Any, BLRDOrdering}()
    SortedDict{String, Any, BLRDOrdering}(BLRDOrder)
end
