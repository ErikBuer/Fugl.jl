import Base: copy!
import Base: splice!
import Base: append!
import Base: push!
import Base: resize!
import Base: setindex!
import Base: getindex
import Base: map
import Base: length
import Base: eltype
import Base: ndims
import Base: size

abstract type GPUArray{T, NDim} <: AbstractArray{T, NDim} end

length(A::GPUArray) = prod(size(A))
eltype(b::GPUArray{T, NDim}) where {T, NDim} = T
endof(A::GPUArray) = length(A)
ndims(A::GPUArray{T, NDim}) where {T, NDim} = NDim
size(A::GPUArray) = (A.len,)
size(A::GPUArray, i::Integer) = i <= ndims(A) ? A.size[i] : 1

function checkdimensions(value::Array, ranges::Union{Integer, UnitRange}...)
    array_size   = size(value)
    indexes_size = map(length, ranges)
    (array_size != indexes_size) && throw(DimensionMismatch("asigning a $array_size to a $(indexes_size) location"))
    true
end
function to_range(index)
    map(index) do val
        isa(val, Integer) && return val:val
        isa(val, Range) && return val
        @error "Indexing only defined for integers or ranges. Found: $val"
    end
end
setindex!(A::GPUArray{T, N}, value::Union{T, Array{T, N}}) where {T, N} = (A[1] = value)

function setindex!(A::GPUArray{T, N}, value, indexes...) where {T, N}
    ranges = to_range(indexes)
    v = isa(value, T) ? [value] : convert(Array{T,N}, value)
    setindex!(A, v, ranges...)
    nothing
end

setindex!(A::GPUArray{T, 2}, value::Vector{T}, i::Integer, range::UnitRange) where {T} =
   (A[i, range] = reshape(value, (length(value),1)))

function setindex!(A::GPUArray{T, N}, value::Array{T, N}, ranges::UnitRange...) where {T, N}
    checkbounds(A, ranges...)
    checkdimensions(value, ranges...)
    gpu_setindex!(A, value, ranges...)
    nothing
end

function update!(A::GPUArray{T, N}, value::Array{T, N}) where {T, N}
    if length(A) != length(value)
        if isa(A, Buffer)
            resize!(A, length(value))
        elseif isa(A, Texture) && ndims(A) == 2
            resize_nocopy!(A, size(value))
        else
            @error "Dynamic resizing not implemented for $(typeof(A))"
        end
    end
    dims = map(x->1:x, size(A))
    A[dims...] = value
    nothing
end

function getindex(A::GPUArray{T, N}, i::Int) where {T, N}
    checkbounds(A, i)
    gpu_getindex(A, i:i)[1] # not as bad as its looks, as so far gpu data must be loaded into an array anyways
end
function getindex(A::GPUArray{T, N}, ranges::UnitRange...) where {T, N}
    checkbounds(A, ranges...)
    gpu_getindex(A, ranges...)
end

resize!(A::GPUArray{T, NDim}, dims::Int...) where {T, NDim} = resize!(A, dims)
function resize!(A::GPUArray{T, NDim}, newdims::NTuple{NDim, Int}) where {T, NDim}
    newdims == size(A) && return A
    gpu_resize!(A, newdims)
    A
end


copy!(a::GPUArray, a_offset::Int, b::Vector,   b_offset::Int, amount::Int) = _copy!(a, a_offset, b, b_offset, amount)
copy!(a::Vector,   a_offset::Int, b::GPUArray, b_offset::Int, amount::Int) = _copy!(a, a_offset, b, b_offset, amount)
copy!(a::GPUArray, a_offset::Int, b::GPUArray, b_offset::Int, amount::Int) = _copy!(a, a_offset, b, b_offset, amount)

#don't overwrite Base.copy! with a::Vector, b::Vector
function _copy!(a::Union{Vector, GPUArray}, a_offset::Int, b::Union{Vector, GPUArray}, b_offset::Int, amount::Int)
    (amount <= 0) && return nothing
    @assert a_offset > 0 && (a_offset-1) + amount <= length(a) "a_offset $a_offset, amount $amount, lengtha $(length(a))"
    @assert b_offset > 0 && (b_offset-1) + amount <= length(b) "b_offset $b_offset, amount $amount, lengthb $(length(b))"
    unsafe_copy!(a, a_offset, b, b_offset, amount)
    return nothing
end

# Interface:
gpu_data(t) = @error "gpu_data not implemented for: $(typeof(t)). This happens, when you call data on an array, without implementing the GPUArray interface"
gpu_resize!(t) = @error "gpu_resize! not implemented for: $(typeof(t)). This happens, when you call resize! on an array, without implementing the GPUArray interface"
gpu_getindex(t) = @error "gpu_getindex not implemented for: $(typeof(t)). This happens, when you call getindex on an array, without implementing the GPUArray interface"
gpu_setindex!(t) = @error "gpu_setindex! not implemented for: $(typeof(t)). This happens, when you call setindex! on an array, without implementing the GPUArray interface"
max_dim(t) = @error "max_dim not implemented for: $(typeof(t)). This happens, when you call setindex! on an array, without implementing the GPUArray interface"


# const BaseSerializer = if isdefined(Base, :AbstractSerializer)
#     Base.AbstractSerializer
# elseif isdefined(Base, :SerializationState)
#     Base.SerializationState
# else
#     error("No Serialization type found. Probably unsupported Julia version")
# end

# function Base.serialize(s::BaseSerializer, t::T) where T<:GPUArray
#     Base.serialize_type(s, T)
#     serialize(s, Array(t))
# end
# function Base.deserialize(s::BaseSerializer, ::Type{T}) where T<:GPUArray
#     A = deserialize(s)
#     T(A)
# end


export data
export resize
export GPUArray

export update!

export gpu_data
export gpu_resize!
export gpu_getindex
export gpu_setindex!
export max_dim
