#came from GLInfo.jl

const GLSL_COMPATIBLE_NUMBER_TYPES = (GLfloat, GLint, GLuint, GLdouble)
const NATIVE_TYPES = Union{
    GLSL_COMPATIBLE_NUMBER_TYPES...,
    Buffer, GPUArray, Shader, Program
}
isa_gl_struct(x::NATIVE_TYPES) = false


opengl_prefix(T)  = @error "Object $T is not a supported uniform element type"
opengl_postfix(T) = @error "Object $T is not a supported uniform element type"


opengl_prefix(x::Type{T}) where {T <: Union{FixedPoint, Float32, Float16}} = ""
opengl_prefix(x::Type{T}) where {T <: Float64} = "d"
opengl_prefix(x::Type{Cint}) = "i"
opengl_prefix(x::Type{T}) where {T <: Union{Cuint, UInt8, UInt16}} = "u"

opengl_postfix(x::Type{Float64}) = "dv"
opengl_postfix(x::Type{Float32}) = "fv"
opengl_postfix(x::Type{Cint})    = "iv"
opengl_postfix(x::Type{Cuint})   = "uiv"


#Came from GLUniforms or GLInfo.jl

glsl_type(::Type{T}) where {T <: AbstractFloat} = Float32
glsl_type(::UniformBuffer{T}) where T = T
glsl_type(::Texture) where {T, N} = gli.GLTexture{glsl_type(T), N}
glsl_typename(x::T) where {T} = glsl_typename(T)
glsl_typename(t::Type{Nothing})     = "Nothing"
glsl_typename(t::Type{GLfloat})  = "float"
glsl_typename(t::Type{GLdouble}) = "double"
glsl_typename(t::Type{GLuint})   = "uint"
glsl_typename(t::Type{GLint})    = "int"
function glsl_typename(t::Type{T}) where {T}
    glasserteltype(T)
    string(opengl_prefix(eltype(T)), "vec", length(T))
end
glsl_typename(t::Type{TextureBuffer{T}}) where {T} = string(opengl_prefix(eltype(T)), "samplerBuffer")

function glsl_typename(t::Texture{T, D}) where {T, D}
    str = string(opengl_prefix(eltype(T)), "sampler", D, "D")
    t.texturetype == GL_TEXTURE_2D_ARRAY && (str *= "Array")
    str
end
function glsl_typename(t::Type{T}) where T <: Matrix

    M, N = size(t)
    string(opengl_prefix(eltype(t)), "mat", M==N ? M : string(M, "x", N))
end
toglsltype_string(x::T) where {T<:Union{Real, Texture, TextureBuffer, Nothing}} = "uniform $(glsl_typename(x))"
#Handle GLSL structs, which need to be addressed via single fields
function toglsltype_string(x::T) where T
    if isa_gl_struct(x)
        string("uniform ", T.name.name)
    else
        @error "can't splice $T into an OpenGL shader. Make sure all fields are of a concrete type and isbits(FieldType)-->true"
    end
end
# Gets used to access a
function glsl_variable_access(keystring, t::Texture{T, D}) where {T,D}
    fields = SubString("rgba", 1, length(T))
    if t.texturetype == GL_TEXTURE_BUFFER
        return string("texelFetch(", keystring, "index).", fields, ";")
    end
    return string("getindex(", keystring, "index).", fields, ";")
end

function glsl_variable_access(keystring, t::Any)
    @error "no glsl variable calculation available for : $(keystring) of type $(typeof(t))"
end

function glsl_version_string()
    glsl = split(unsafe_string(glGetString(GL_SHADING_LANGUAGE_VERSION)), ['.', ' '])
    if length(glsl) >= 2
        glsl = VersionNumber(parse(Int, glsl[1]), parse(Int, glsl[2]))
        glsl.major == 1 && glsl.minor <= 2 && (@error "OpenGL shading Language version too low. Try updating graphic driver!")
        glsl_version = string(glsl.major) * rpad(string(glsl.minor),2,"0")
        return "#version $(glsl_version)\n"
    else
        @error "could not parse GLSL version: $glsl"
    end
end
