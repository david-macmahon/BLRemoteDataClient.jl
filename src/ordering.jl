# Defines a BLRDOrdering type that sorts "hostname" and "filename" to the end.

using Base: Ordering, Forward
import Base: lt
import DataStructures: SortedDict

struct BLRDOrdering <: Ordering
end

const BLRDOrder = BLRDOrdering()

function lt(::BLRDOrdering, a, b)
    a == "filename" ? false :
    b == "filename" ? true  :
    a == "hostname" ? (b == "filename") :
    b == "hostname" ? true : lt(Forward, a, b)
end

function SortedDict{String, Any, BLRDOrdering}()
    SortedDict{String, Any, BLRDOrdering}(BLRDOrder)
end
