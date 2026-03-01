

########################################################################################
# OpenGL Arrays
"""
Transform julia datatypes to opengl enum type
"""
julia2glenum(x::Type{T}) where {T <: FixedPoint} = julia2glenum(FixedPointNumbers.rawtype(x))
# julia2glenum(x::Type{OffsetInteger{O, T}}) where {O, T} = julia2glenum(T)
julia2glenum(::Type{GLubyte})  = GL_UNSIGNED_BYTE
julia2glenum(::Type{GLbyte})   = GL_BYTE
julia2glenum(::Type{GLuint})   = GL_UNSIGNED_INT
julia2glenum(::Type{GLushort}) = GL_UNSIGNED_SHORT
julia2glenum(::Type{GLshort})  = GL_SHORT
julia2glenum(::Type{GLint})    = GL_INT
julia2glenum(::Type{GLfloat})  = GL_FLOAT
julia2glenum(::Type{GLdouble}) = GL_DOUBLE
julia2glenum(::Type{Float16})  = GL_HALF_FLOAT
function julia2glenum(::Type{T}) where T
    glasserteltype(T)
    julia2glenum(eltype(T))
end

gl_convert(a::T) where {T <: NATIVE_TYPES} = a
gl_convert(::Type{T}, a::NATIVE_TYPES; kw_args...) where {T <: NATIVE_TYPES} = a


gl_promote(x::Type{T}) where {T <: Integer} = Cint
gl_promote(x::Type{Union{Int16, Int8}}) = x

gl_promote(x::Type{T}) where {T <: Unsigned} = Cuint
gl_promote(x::Type{Union{UInt16, UInt8}}) = x

gl_promote(x::Type{T}) where {T <: AbstractFloat} = Float32
gl_promote(x::Type{Float16}) = x

gl_promote(x::Type{T}) where {T <: Normed} = N0f32
gl_promote(x::Type{N0f16}) = x
gl_promote(x::Type{N0f8}) = x

gl_promote(x::Type{Bool}) = GLboolean

function gl_promote(x::Type{T}) where T
    glasserteltype(T)
    similar_type(T, gl_promote(eltype(T)))
end

gl_convert(x::T) where {T <: Number} = gl_promote(T)(x)
gl_convert(s::Nothing) = s

isa_gl_struct(x::Array) = false
function isa_gl_struct(x::T) where T
    !isleaftype(T) && return false
    if T <: Tuple
        return false
    end
    fnames = fieldnames(T)
    !isempty(fnames) && all(name -> isleaftype(fieldtype(T, name)) && isbits(getfield(x, name)), fnames)
end
function gl_convert_struct(x::T, uniform_name::Symbol) where T
    if isa_gl_struct(x)
        return Dict{Symbol, Any}(map(fieldnames(x)) do name
            (Symbol("$uniform_name.$name") => gl_convert(getfield(x, name)))
        end)
    else
        @error "can't convert $x to a OpenGL type. Make sure all fields are of a concrete type and isbits(FieldType)-->true"
    end
end

function gl_convert(::Type{T}, a::Array{X, N}; kw_args...) where {T <: GPUArray, X, N}
    T(map(gl_promote(X), a); kw_args...)
end
function gl_convert(::Type{T}, a::Vector{Array{X, 2}}; kw_args...) where {T <: Texture, X}
    T(a; kw_args...)
end


gl_convert(f::Function, a) = f(a)
