function iscompiled(shader::GLuint)
    success = GLint[0]
    glGetShaderiv(shader, GL_COMPILE_STATUS, success)
    return first(success) == GL_TRUE
end

abstract type AbstractShader end

struct Shader <: AbstractShader
    id      ::GLuint
    typ     ::GLenum
    source  ::Vector{UInt8} #UInt representation of the source program string,
end

function Shader(typ, source)
    id = glCreateShader(typ)::GLuint
    @assert id > 0 "opengl context is not active or shader type not accepted. Shadertype: $(GLENUM(typ).name)"
    s = Vector{UInt8}(source)
    glShaderSource(id, s)
    glCompileShader(id)
    if !iscompiled(id)
        print_with_lines(String(s))
        @error "shader id $(id) of type $(typ) didn't compile. \n$(getinfolog(id))"
    end
    Shader(id, typ, s)
end
Shader(typ_source::Tuple) = Shader(typ_source...)

function Shader(path::String)
    source_str = read(open(path), String)
    typ = shadertype(path)
    source = Vector{UInt8}(source_str)
    Shader(typ, source)
end

shadertype(s::Shader) = s.typ

import Base: ==
(==)(a::Shader, b::Shader) = a.source == b.source && a.typ == b.typ && a.id == b.id && a.context == b.context
Base.hash(s::Shader, h::UInt64) = hash((s.source, s.typ, s.id, s.context), h)

function Base.show(io::IO, shader::Shader)
    println(io, GLENUM(shader.typ).name)
    println(io, "id: $(shader.id)")
    println(io, "source:")
    print_with_lines(io, String(shader.source))
end

function shadertype(path::AbstractString)
    p, ext = splitext(path)
    ext == ".comp" && return GL_COMPUTE_SHADER
    ext == ".vert" && return GL_VERTEX_SHADER
    ext == ".frag" && return GL_FRAGMENT_SHADER
    ext == ".geom" && return GL_GEOMETRY_SHADER
    @error "$ext not a valid shader extension."
end
function shadertype(typ::Symbol)
    (typ == :compute  || typ == :comp) && return GL_COMPUTE_SHADER
    (typ == :vertex   || typ == :vert) && return GL_VERTEX_SHADER
    (typ == :fragment || typ == :frag) && return GL_FRAGMENT_SHADER
    (typ == :geometry || typ == :geom) && return GL_GEOMETRY_SHADER
    @error "$typ not a valid shader symbol."
end

# Different shader string literals- usage: e.g. frag" my shader code"
macro frag_str(source::AbstractString)
    quote
        (GL_FRAGMENT_SHADER, $source)
    end
end
macro vert_str(source::AbstractString)
    quote
        (GL_VERTEX_SHADER, $source)
    end
end
macro geom_str(source::AbstractString)
    quote
        (GL_GEOMETRY_SHADER, $source)
    end
end
macro comp_str(source::AbstractString)
    quote
        (GL_COMPUTE_SHADER, $source)
    end
end

function getinfolog(id::GLuint)
    # Get the maximum possible length for the descriptive error message
    maxlength = GLint[0]
    glGetShaderiv(id, GL_INFO_LOG_LENGTH, maxlength)
    maxlength = first(maxlength)
    # Return the text of the message if there is any
    if maxlength > 0
        buffer = zeros(GLchar, maxlength)
        sizei = GLsizei[0]
        glGetShaderInfoLog(id, maxlength, sizei, buffer)
        length = first(sizei)
        return unsafe_string(pointer(buffer), length)
    else
        return "success"
    end
end
