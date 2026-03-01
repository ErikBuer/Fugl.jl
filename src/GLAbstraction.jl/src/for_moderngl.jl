#=
This is the place, where I put functions, which are so annoying in OpenGL, that I felt the need to wrap them and make them more "Julian"
Its also to do some more complex error handling, not handled by the debug callback
=#
getnames(check_function::Function) = filter(check_function, uint32(0:65534))
# gets all the names currently boundo to programs
getProgramNames() = getnames(glIsProgram)
getShaderNames() = getnames(glIsShader)
getVertexArrayNames() = getnames(glIsVertexArray)

function glGetShaderiv(shaderID::GLuint, variable::GLenum)
    result = Ref{GLint}(-1)
    glGetShaderiv(shaderID, variable, result)
    result[]
end
function glShaderSource(shaderID::GLuint, shadercode::Vector{UInt8})
    shader_code_ptrs = Ptr{UInt8}[pointer(shadercode)]
    len = Ref{GLint}(length(shadercode))
    glShaderSource(shaderID, 1, shader_code_ptrs, len)
end
glShaderSource(shaderID::GLuint, shadercode::String) = glShaderSource(shaderID, Vector{UInt8}(shadercode))
function glGetAttachedShaders(program::GLuint)
    shader_count   = glGetProgramiv(program, GL_ATTACHED_SHADERS)
    length_written = GLsizei[0]
    shaders        = zeros(GLuint, shader_count)

    glGetAttachedShaders(program, shader_count, length_written, shaders)
    shaders[1:first(length_written)]
end

function ModernGL.glGetActiveUniformsiv(program::GLuint, index, var::GLenum)
    result = Ref{GLint}(-1)
    glGetActiveUniformsiv(program, 1, Ref{GLuint}(index), var, result)
    result[]
end

function glGetActiveUniform(programID::GLuint, index::Integer)
    actualLength   = GLsizei[1]
    uniformSize    = GLint[1]
    typ            = GLenum[1]
    maxcharsize    = glGetProgramiv(programID, GL_ACTIVE_UNIFORM_MAX_LENGTH)
    name           = zeros(GLchar, maxcharsize)

    glGetActiveUniform(programID, index, maxcharsize, actualLength, uniformSize, typ, name)

    actualLength[1] <= 0 &&  @error "No active uniform at given index. Index: $index"

    uname = unsafe_string(pointer(name), actualLength[1])
    uname = Symbol(replace(uname, r"\[\d*\]" => "")) # replace array brackets. This is not really a good solution.
    (uname, typ[1], uniformSize[1])
end
glGetActiveUniformName(program::GLuint, index::Integer) = glGetActiveUniform(program, index)[1]

function glGetActiveAttrib(programID::GLuint, index::Integer)
    actualLength   = GLsizei[1]
    attributeSize  = GLint[1]
    typ            = GLenum[1]
    maxcharsize    = glGetProgramiv(programID, GL_ACTIVE_ATTRIBUTE_MAX_LENGTH)
    name           = zeros(GLchar, maxcharsize)

    glGetActiveAttrib(programID, index, maxcharsize, actualLength, attributeSize, typ, name)

    actualLength[1] <= 0 && @error "No active uniform at given index. Index: $index"

    uname = unsafe_string(pointer(name), actualLength[1])
    uname = Symbol(replace(uname, r"\[\d*\]" => "")) # replace array brackets. This is not really a good solution.
    (uname, typ[1], attributeSize[1])
end
function glGetProgramiv(programID::GLuint, variable::GLenum)
    result = Ref{GLint}(-1)
    glGetProgramiv(programID, variable, result)
    result[]
end
function glGetIntegerv(variable::GLenum)
    result = Ref{GLint}(-1)
    glGetIntegerv(UInt32(variable), result)
    result[]
end

function glGenBuffers(n=1)
    result = GLuint[0]
    glGenBuffers(1, result)
    id = result[]
    if id <= 0
        @error "glGenBuffers returned invalid id. OpenGL Context active?"
    end
    id
end
function glGenVertexArrays()
    result = GLuint[0]
    glGenVertexArrays(1, result)
    id = result[1]
    if id <= 0
        @error "glGenVertexArrays returned invalid id. OpenGL Context active?"
    end
    id
end
function glGenTextures()
    result = GLuint[0]
    glGenTextures(1, result)
    id = result[1]
    if id <= 0
        @error "glGenTextures returned invalid id. OpenGL Context active?"
    end
    id
end
function glGenFramebuffers()
    result = GLuint[0]
    glGenFramebuffers(1, result)
    id = result[1]
    if id <= 0
        @error "glGenFramebuffers returned invalid id. OpenGL Context active?"
    end
    id
end

function glDeleteTextures(id::GLuint)
  arr = [id]
  glDeleteTextures(1, arr)
end
function glDeleteVertexArrays(id::GLuint)
  arr = [id]
  glDeleteVertexArrays(1, arr)
end
function glDeleteBuffers(id::GLuint)
  arr = [id]
  glDeleteBuffers(1, arr)
end

function glGetTexLevelParameteriv(target::GLenum, level, name::GLenum)
  result = GLint[0]
  glGetTexLevelParameteriv(target, level, name, result)
  result[1]
end

function glGenRenderbuffers(format::GLenum, attachment::GLenum, dimensions)
    renderbuffer = GLuint[0]
    glGenRenderbuffers(1, renderbuffer)
    glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer[1])
    glRenderbufferStorage(GL_RENDERBUFFER, format, dimensions...)
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, attachment, GL_RENDERBUFFER, renderbuffer[1])
    renderbuffer[1]
end

function glTexImage(ttype::GLenum, level::Integer, internalFormat::GLenum, w::Integer, h::Integer, d::Integer, border::Integer, format::GLenum, datatype::GLenum, data)
    glTexImage3D(GL_PROXY_TEXTURE_3D, level, internalFormat, w, h, d, border, format, datatype, C_NULL)
    for l in  0:level
        result = glGetTexLevelParameteriv(GL_PROXY_TEXTURE_3D, l, GL_TEXTURE_WIDTH)
        if result == 0
            @error "glTexImage 3D: width too large. Width: $w"
        end
        result = glGetTexLevelParameteriv(GL_PROXY_TEXTURE_3D, l,GL_TEXTURE_HEIGHT)
        if result == 0
            @error "glTexImage 3D: height too large. height: $h"
        end
        result = glGetTexLevelParameteriv(GL_PROXY_TEXTURE_3D, l, GL_TEXTURE_DEPTH)
        if result == 0
            @error "glTexImage 3D: depth too large. Depth: $d"
        end
        result = glGetTexLevelParameteriv(GL_PROXY_TEXTURE_3D, l, GL_TEXTURE_INTERNAL_FORMAT)
        if result == 0
            @error "glTexImage 3D: internal format not valid. format: $(GLENUM(internalFormat).name)"
        end
    end
    glTexImage3D(ttype, level, internalFormat, w, h, d, border, format, datatype, data)
end
function glTexImage(ttype::GLenum, level::Integer, internalFormat::GLenum, w::Integer, h::Integer, border::Integer, format::GLenum, datatype::GLenum, data)
    glTexImage2D(GL_PROXY_TEXTURE_2D, level, internalFormat, w, h, border, format, datatype, C_NULL)
    for l in 0:level
        result = glGetTexLevelParameteriv(GL_PROXY_TEXTURE_2D, l, GL_TEXTURE_WIDTH)
        if result == 0
            @error "glTexImage 2D: width too large. Width: $w"
        end
        result = glGetTexLevelParameteriv(GL_PROXY_TEXTURE_2D, l, GL_TEXTURE_HEIGHT)
        if result == 0
            @error "glTexImage 2D: height too large. height: $h"
        end
        result = glGetTexLevelParameteriv(GL_PROXY_TEXTURE_2D, l, GL_TEXTURE_INTERNAL_FORMAT)
        if result == 0
            @error "glTexImage 2D: internal format not valid. format: $(GLENUM(internalFormat).name)"
        end
    end
    glTexImage2D(ttype, level, internalFormat, w, h, border, format, datatype, data)
end
function glTexImage(ttype::GLenum, level::Integer, internalFormat::GLenum, w::Integer, border::Integer, format::GLenum, datatype::GLenum, data)
    glTexImage1D(GL_PROXY_TEXTURE_1D, level, internalFormat, w, border, format, datatype, C_NULL)
    for l in 0:level
        result = glGetTexLevelParameteriv(GL_PROXY_TEXTURE_1D, l, GL_TEXTURE_WIDTH)
        if result == 0
            @error "glTexImage 1D: width too large. Width: $w"
        end
        result = glGetTexLevelParameteriv(GL_PROXY_TEXTURE_1D, l, GL_TEXTURE_INTERNAL_FORMAT)
        if result == 0
            @error "glTexImage 1D: internal format not valid. format: $(GLENUM(internalFormat).name)"
        end
    end
    glTexImage1D(ttype, level, internalFormat, w, border, format, datatype, data)
end

function compile_program(shaders::GLuint...)

    program = glCreateProgram()::GLuint
    glUseProgram(program)
    #attach new ones
    foreach(shaders) do shader
        glAttachShader(program, shader.id)
    end
    #link program
    glLinkProgram(program)
    if !islinked(program)
        for shader in shaders
            write(stdout, shader.source)
            println("---------------------------")
        end
        @error "program $program not linked. Error in: \n $(join(map(x-> string(x.name), shaders))), or, \n $(getinfolog(program))"
    end
    program
end

# function glsl_version_string()
#     glsl = split(unsafe_string(glGetString(GL_SHADING_LANGUAGE_VERSION)), ['.', ' '])
#     if length(glsl) >= 2
#         glsl = VersionNumber(parse(Int, glsl[1]), parse(Int, glsl[2]))
#         glsl.major == 1 && glsl.minor <= 2 && (@error "OpenGL shading Language version too low. Try updating graphic driver!")
#         glsl_version = string(glsl.major) * rpad(string(glsl.minor),2,"0")
#         return "#version $(glsl_version)\n"
#     else
#         @error "could not parse GLSL version: $glsl"
#     end
# end
