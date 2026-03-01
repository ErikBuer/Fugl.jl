islinked(program::GLuint) = glGetProgramiv(program, GL_LINK_STATUS) == GL_TRUE

const AttributeTuple = NamedTuple{(:name, :location, :T, :size), Tuple{Symbol, GLint, GLenum,  GLint}}
const UniformTuple = AttributeTuple
const INVALID_ATTRIBUTE = GLint(-1)
const INVALID_UNIFORM   = GLint(-1)

function setup_uniforms(program::GLuint)
    info = UniformTuple[]
    nuniforms = glGetProgramiv(program, GL_ACTIVE_UNIFORMS)
    for i=1:nuniforms
        name, typ, size = glGetActiveUniform(program, i-1)
        loc = glGetUniformLocation(program, name)
        push!(info, (name = name, location = loc, T = typ, size = size))
    end
    return info
end

function setup_attributes(program::GLuint)
    info = AttributeTuple[]
    nattribs = glGetProgramiv(program, GL_ACTIVE_ATTRIBUTES)
    for i=1:nattribs
        name, typ, size = glGetActiveAttrib(program, i-1)
        loc = glGetAttribLocation(program, name)
        push!(info, (name = name, location = loc, T = typ, size = size))
    end
    return info
end

abstract type AbstractProgram end
mutable struct Program <: AbstractProgram
    id        ::GLuint
    shaders   ::Vector{Shader}
    uniforms  ::Vector{UniformTuple}
    attributes::Vector{AttributeTuple}
    context
    function Program(shaders::Vector{Shader}, fragdatalocation::Vector{Tuple{Int, String}})
        # Remove old shaders
        exists_context()
        program = glCreateProgram()::GLuint
        glUseProgram(program)
        #attach new ones
        foreach(shaders) do shader
            glAttachShader(program, shader.id)
        end

        #Bind frag data
        for (location, name) in fragdatalocation
            glBindFragDataLocation(program, location, ascii(name))
        end

        #link program
        glLinkProgram(program)
        if !islinked(program)
            for shader in shaders
                write(stdout, shader.source)
                println("---------------------------")
            end
            @error "program $program not linked. Error in: \n $(join(map(x->x.id, shaders), " or ")), \n $(getinfolog(program))"
        end

        # generate the link locations
        uniforms = setup_uniforms(program)
        attribs  = setup_attributes(program)
        prog = new(program, shaders, uniforms, attribs, current_context())
        finalizer(free!, prog)
        prog
    end
end

Program(shaders::Vector{Shader}) = Program(shaders, Tuple{Int, String}[])
Program(shaders::Shader...) = Program([shaders...])

#REVIEW: This is a bit redundant seen as there is `load(source)` from FilIO for shaders but ok
Program(sh_string_typ...) = 
    Program([map(x -> Shader(x), sh_string_typ)...])

free!(x::Program) = context_command(() -> glDeleteProgram(x.id), x.context)

attributes(program::Program) = program.attributes
uniforms(program::Program)   = program.uniforms
uniform_names(program::Program) = [x.name for x in program.uniforms]

attribute(program::Program, name::Symbol) =
    getfirst(x -> x.name == name, program.attributes)
uniform(program::Program, name::Symbol) =
    getfirst(x -> x.name == name, program.uniforms)

function attribute_location(program::Program, name::Symbol)
    att = attribute(program, name)
    return att != nothing ? att.location : INVALID_ATTRIBUTE
end

function uniform_location(program::Program, name::Symbol)
    u = uniform(program, name)
    return u != nothing ? u.location : INVALID_UNIFORM
end

function attribute_type(program::Program, name::Symbol)
    att = attribute(program, name)
    return att != nothing ? att.T : Nothing
end

function uniform_type(program::Program, name::Symbol)
    u = uniform(program, name)
    return u != nothing ? u.T : Nothing
end

function attribute_size(program::Program, name::Symbol)
    att = attribute(program, name)
    return att != nothing ? att.size : INVALID_ATTRIBUTE
end

function uniform_size(program::Program, name::Symbol)
    u = uniform(program, name)
    return u != nothing ? u.size : INVALID_UNIFORM
end

bind(program::Program) = glUseProgram(program.id)
unbind(program::AbstractProgram) = glUseProgram(0)

#REVIEW: Not sure if this is the best design decision
#REVIEW: Naming?
function gluniform(program::Program, name::Symbol, vals...)
    u = uniform_location(program, name)
    if u != INVALID_UNIFORM
        gluniform(u, vals...)
    end
end

function Base.show(io::IO, p::Program)
    println(io, "Program: $(p.id)")
    println(io, "Shaders:")
    for shader in p.shaders
        println(io, shader)
    end
    println(io, "attributes:")
    for a in p.attributes
        println(io, "   ", a.name, "::", GLENUM(a.T).name)
    end
    println(io, "uniforms:")
    for u in p.uniforms
        println(io, "   ", u.name, "::", GLENUM(u.T).name)
    end
end

infolog(program::Program) = getinfolog(program.id)

# display program's information
function program_info(p::Program)
    result = Dict{Symbol, Any}()
    program = p.id
    # check if name is really a program
    result[:program] = program
    # Get the shader's name
    result[:shaders] = glGetAttachedShaders(program)
    for shader in result[:shaders]
        result[Symbol("shader_type_$shader")] = GLENUM(convert(GLenum, glGetShaderiv(shader, GL_SHADER_TYPE))).name
    end
    # Get program info
    result[:program_seperable] = glGetProgramiv(program, GL_PROGRAM_SEPARABLE)
    result[:binary_retrievable_hint] = glGetProgramiv(program, GL_PROGRAM_BINARY_RETRIEVABLE_HINT)
    result[:link_status] = glGetProgramiv(program, GL_LINK_STATUS)
    result[:validate_status] = glGetProgramiv(program, GL_VALIDATE_STATUS)
    result[:delete_status] = glGetProgramiv(program, GL_DELETE_STATUS)
    result[:active_attributes] = glGetProgramiv(program, GL_ACTIVE_ATTRIBUTES)
    result[:active_uniforms] = glGetProgramiv(program, GL_ACTIVE_UNIFORMS)
    result[:active_uniform_blocks] = glGetProgramiv(program, GL_ACTIVE_UNIFORM_BLOCKS)
    result[:active_atomic_counter_buffers] = glGetProgramiv(program, GL_ACTIVE_ATOMIC_COUNTER_BUFFERS)
    result[:transform_feedback_buffer_mode] = glGetProgramiv(program, GL_TRANSFORM_FEEDBACK_BUFFER_MODE)
    result[:transform_feedback_varyings] = glGetProgramiv(program, GL_TRANSFORM_FEEDBACK_VARYINGS)
    result
end

###############################################################################333

mutable struct LazyProgram <: AbstractProgram
    sources::Vector
    data::Dict
    compiled_program::Union{Program, Nothing}
end
LazyProgram(sources...; data...) = LazyProgram(Vector(sources), Dict(data), nothing)

function Program(lazy_program::LazyProgram)
    fragdatalocation = get(lazy_program.data, :fragdatalocation, Tuple{Int, String}[])
    shaders = haskey(lazy_program.data, :arguments) ? Shader.(lazy_program.sources, Ref(lazy_program.data[:arguments])) : Shader.()
    return Program([shaders...], fragdatalocation)
end
function bind(program::LazyProgram)
    iscompiled_orcompile!(program)
    bind(program.compiled_program)
end

function iscompiled_orcompile!(program::LazyProgram)
    if program.compiled_program == nothing
        program.compiled_program = Program(program)
    end
end

####################################################################################
# freeing

# OpenGL has the annoying habit of reusing id's when creating a new context
# We need to make sure to only free the current one


# display the values for a uniform in a named block
function uniform_in_block_info(p::Program, blockName, uniName)
    result = Dict{Symbol, Any}()
    program = p.id

    result[:index] = glGetUniformBlockIndex(program, blockName)
    if (index == GL_INVALID_INDEX)
        println("$uniName is not a valid uniform name in block $blockName")
    end
    result[:bindIndex] = glGetActiveUniformBlockiv(program, index, GL_UNIFORM_BLOCK_BINDING)
    result[:bufferIndex] = glGetIntegeri_v(GL_UNIFORM_BUFFER_BINDING, result[:bindIndex])
    result[:uniIndex] = glGetUniformIndices(program, uniName)
    uniIndex = result[:uniIndex]
    result[:uniType] = glGetActiveUniformsiv(program, uniIndex, GL_UNIFORM_TYPE)
    result[:uniOffset] = glGetActiveUniformsiv(program, uniIndex, GL_UNIFORM_OFFSET)
    result[:uniSize] = glGetActiveUniformsiv(program, uniIndex, GL_UNIFORM_SIZE)
    result[:uniArrayStride] = glGetActiveUniformsiv(program, uniIndex, GL_UNIFORM_ARRAY_STRIDE)
    result[:uniMatStride] = glGetActiveUniformsiv(program, uniIndex, GL_UNIFORM_MATRIX_STRIDE)
    result
end
