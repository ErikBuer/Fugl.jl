const GLSLScalarTypes = Union{Float32, Int32, UInt32}

"""
Statically sized uniform buffer.
Supports push!, but with fixed memory, so it will error after reaching
it's preallocated length.
"""
struct UniformBuffer{T, N}
    buffer::Buffer{T}
    offsets::NTuple{N, Int}
    elementsize::Int
    length::Int
end

"""
    Pre allocates an empty buffer with `max_batch_size` size
    which can be used to store multiple uniform blocks of type T
"""
function UniformBuffer(::Type{T}, max_batch_size = 1024, mode = GL_STATIC_DRAW) where T
    offsets, elementsize = std140_offsets(T)
    buffer = Buffer{T}(
        max_batch_size,
        elementsize * max_batch_size,
        GL_UNIFORM_BUFFER, mode
    )
    UniformBuffer(buffer, offsets, elementsize, 0)
end
"""
    Creates an Uniform buffer with the contents of `data`
"""
function UniformBuffer{T}(data::T, mode = GL_STATIC_DRAW) where T
    buffer = UniformBuffer(T, 1, mode)
    push!(buffer, data)
    buffer
end

"""
Returns the alignment of the `Type` of T as assumed in https://khronos.org/registry/OpenGL/specs/gl/glspec45.core.pdf#page=159,
returning a tuple with the first element being the 'base' alignment, and the second the total size inside memory.
"""
function glsl_alignment_size(T)
    function ceil4(i)
        while i%4 != 0
            i += 1
        end
        return i
    end
    T <: Bool && return sizeof(Int32), sizeof(Int32)
    N = sizeof(T)
    T <: GLSLScalarTypes && return N, N
    T <: Function && return sizeof(Vec4f0), sizeof(Vec4f0) # sizeof(EmptyStruct) padded to Vec4f0
    ET = eltype(T)
    N  = sizeof(ET)
    if T <: Matrix
        nrows, ncols = size(T)
        ncols        = ceil4(ncols)
        return div(ncols, 4) * N, ncols * nrows * N
    end
    if T <: Vector
        return ceil4(length(T)) * N, length(T) * N
    end
    @error "Struct $T not supported yet. Please help by implementing all rules from https://khronos.org/registry/OpenGL/specs/gl/glspec45.core.pdf#page=159"
end

function std140_offsets(::Type{T}) where T
    elementsize = 0
    offsets = if T <: GLSLScalarTypes
        elementsize = sizeof(T)
        (0,)
    else
        offset = 0
        offsets = ntuple(nfields(T)) do i
            ft = fieldtype(T, i)
            alignement, sz = glsl_alignment_size(ft)
            if offset % alignement != 0
                offset = (div(offset, alignement) + 1) * alignement
            end
            of = offset
            offset += sz
            of
        end
        elementsize = offset
        offsets
    end
    offsets, elementsize
end

Base.convert(::Type{UniformBuffer}, x) = UniformBuffer(x)
Base.convert(::Type{UniformBuffer}, x::UniformBuffer) = x
Base.eltype(::UniformBuffer{T}) where T = T

function Base.setindex!(buffer::UniformBuffer{T}, element::T, idx::Integer) where T
    if idx > length(buffer.buffer)
        throw(BoundsError(buffer, idx))
    end
    buff = buffer.buffer
    glBindBuffer(buff.buffertype, buff.id)
    dptr = Ptr{UInt8}(glMapBuffer(buff.buffertype, GL_WRITE_ONLY))
    for (offset, ptr, size) in iterate_fields(buffer, element, idx)
        unsafe_copy!(dptr + offset, ptr, size)
    end
    glUnmapBuffer(buff.buffertype)
    bind(buff, 0)
    element
end

function Base.push!(buffer::UniformBuffer{T}, element::T) where T
    buffer.length += 1
    buffer[buffer.length] = element
    buffer
end

function assert_blocksize(buffer::UniformBuffer, program, blockname::String)
    block_index = glGetUniformBlockIndex(program, blockname)
    blocksize_ref = Ref{GLint}(0)
    glGetActiveUniformBlockiv(
        program, block_index,
        GL_UNIFORM_BLOCK_DATA_SIZE, blocksize_ref
    )
    blocksize = blocksize_ref[]
    @assert buffer.elementsize * length(buffer.buffer) == blocksize
end

_getfield(x::GLSLScalarTypes, i) = x
_getfield(x, i) = getfield(x, i)

function iterate_fields(buffer::UniformBuffer{T, N}, x, index) where {T, N}
    offset = buffer.elementsize * (index - 1)
    x_ref = isimmutable(x) ? Ref(x) : x
    base_ptr = Ptr{UInt8}(pointer_from_objref(x_ref))
    ntuple(Val{N}) do i
        offset + buffer.offsets[i], base_ptr + fieldoffset(T, i), sizeof(fieldtype(T, i))
    end
end

extract_val(::Val{X}) where X = X

# function Base.setindex!{T <: Composable, N, TF}(x::UniformBuffer{T, N}, val::TF, field::Type{<: Field})
#     index = extract_val(FieldTraits.fieldindex(T, field))
#     if index === 0
#         throw(BoundsError(x, field))
#     end
#     val_conv = convert(fieldtype(T, index), val)
#     val_ref = if isbits(val)
#         Base.Ref(val)
#     elseif isimmutable(val)
#         error("Struct $TF contains pointers and can't be transferred to GPU")
#     else
#         pointer_from_objref(val)
#     end
#     buff = x.buffer
#     bind(buff) do
#         BufferSubData(buff.buffertype, x.offsets[index], sizeof(val_conv), val_ref)
#     end
#     x
# end

# function Base.getindex{T <: Composable, N}(x::UniformBuffer{T, N}, field::Type{<: Field})
#     index = extract_val(FieldTraits.fieldindex(T, field)[1])
#     if index == 0
#         throw(BoundsError(x, field))
#     end
#     ET = fieldtype(T, index)
#     val_ref = Ref{ET}()
#     bind(x.buffer) do
#         glGetBufferSubData(x.buffer.buffertype, x.offsets[index], sizeof(ET), val_ref)
#     end
#     val_ref[]
# end
