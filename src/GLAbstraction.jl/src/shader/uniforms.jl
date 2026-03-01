###======================================================####
#Came from GLAbstraction/GLUniforms.jl

# Uniforms are OpenGL variables that stay the same for the entirety of a drawcall.
# There are a lot of functions, to upload them, as OpenGL doesn't rely on multiple dispatch.
# here is my approach, to handle all of the uniforms with one function, namely gluniform
# For uniforms, the Vector and Matrix types from ImmutableArrays should be used, as they map the relation almost 1:1

const GLSL_COMPATIBLE_NUMBER_TYPES = (GLfloat, GLint, GLuint, GLdouble)

function uniformfunc(typ::DataType, dims::Tuple{Int})
    Symbol(string("glUniform", first(dims), opengl_postfix(typ)))
end
function uniformfunc(typ::DataType, dims::Tuple{Int, Int})
    M, N = dims
    Symbol(string("glUniformMatrix", M == N ? "$M" : "$(M)x$(N)", opengl_postfix(typ)))
end

function gluniform(location::Integer, x::StaticArray)
    xref = [x]
    gluniform(location, xref)
end

@generated function gluniform(location::Integer, x::Vector{FSA}) where FSA <: StaticArray
    func = uniformfunc(eltype(FSA), size(FSA))
    callexpr = if ndims(FSA) == 2
        :($func(location, length(x), GL_FALSE, xref))
    else
        :($func(location, length(x), xref))
    end
    quote
        xref = reinterpret(eltype(FSA), x)
        $callexpr
    end
end
 
#Some additional uniform functions, not related to Imutable Arrays
# gluniform(location::Integer, target::Integer, t::Texture) = gluniform(GLint(location), GLint(target), t)
# gluniform(location::Integer, target::Integer, t::GPUVector) = gluniform(GLint(location), GLint(target), t.buffer)
# gluniform(location::Integer, target::Integer, t::TextureBuffer) = gluniform(GLint(location), GLint(target), t.texture)
# gluniform(location::Integer, t::TextureBuffer) = gluniform(GLint(location), GLint(target), t.texture)
#REVIEW: scary, binding and making texture active seems like something that shouldn't be in gluniform...

#TODO: We have the tools to figure out what texture unit a texture with a given name should be bound to, but we have to make it so that low level functionality remains to avoid slowness
gluniform(location::Integer, target::Integer, t::TextureBuffer) = gluniform(GLint(location), GLint(target), t.texture)
function gluniform(location::GLint, texture_unit, t::Texture)
    tu = GL_TEXTURE0 + UInt32(texture_unit)
    glActiveTexture(tu)
    glBindTexture(t.texturetype, t.id)
    gluniform(location, GLint(texture_unit))
end
gluniform(location::Integer, x::Enum)                                = gluniform(GLint(location), GLint(x))
gluniform(location::Integer, x::Union{GLubyte, GLushort, GLuint})    = glUniform1ui(GLint(location), x)
gluniform(location::Integer, x::Union{GLbyte, GLshort, GLint, Bool}) = glUniform1i(GLint(location),  x)
gluniform(location::Integer, x::GLfloat)                             = glUniform1f(GLint(location),  x)
gluniform(location::Integer, x::GLdouble)                            = glUniform1d(GLint(location),  x)

#Uniform upload functions for julia arrays...
gluniform(location::GLint, x::Vector{Float32})                       = glUniform1fv(location, length(x), x)
gluniform(location::GLint, x::Vector{GLdouble})                      = glUniform1dv(location, length(x), x)
gluniform(location::GLint, x::Vector{GLint})                         = glUniform1iv(location, length(x), x)
gluniform(location::GLint, x::Vector{GLuint})                        = glUniform1uiv(location, length(x), x)
