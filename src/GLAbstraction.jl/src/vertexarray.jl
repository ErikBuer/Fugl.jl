
@enum VaoKind SIMPLE ELEMENTS ELEMENTS_INSTANCED EMPTY

# buffers which are not instanced have divisor = -1
const GEOMETRY_DIVISOR = GLint(-1)
const UNIFORM_DIVISOR = GLint(1)

struct BufferAttachmentInfo{T}
	name     ::Symbol
    location ::GLint
    buffer   ::Buffer{T}
    divisor  ::GLint
end

Base.eltype(b::BufferAttachmentInfo{T}) where T = T

function generate_buffers(program::Program, divisor::GLint=GEOMETRY_DIVISOR; name_buffers...)
	buflen  = 0
    buffers = BufferAttachmentInfo[]
    for (name, val) in pairs(name_buffers)
        loc = attribute_location(program, name)
        if loc != INVALID_ATTRIBUTE
	        buflen = buflen == 0 ? length(val) : buflen 
            vallen = length(val)
            if vallen == buflen
                push!(buffers, BufferAttachmentInfo(name, loc, Buffer(val, usage=GL_DYNAMIC_DRAW), divisor))
            elseif !isa(val, Vector)
                push!(buffers, BufferAttachmentInfo(name, loc, Buffer(fill(val, buflen), usage=GL_DYNAMIC_DRAW), divisor))
            end
        else
            error("Invalid attribute: $name.")
        end
    end
    return buffers
end

mutable struct VertexArray{Vertex, Kind}
    id         ::GLuint
    bufferinfos::Vector{<:BufferAttachmentInfo}
    indices    ::Union{Buffer, Nothing}
    nverts     ::GLint #total vertices to be drawn in drawcall
    ninst      ::GLint
    face       ::GLenum
    context    ::Context 
    function VertexArray(kind::VaoKind, bufferinfos::Vector{<:BufferAttachmentInfo}, indices, ninst, face)
        id = glGenVertexArrays()
        glBindVertexArray(id)

        nverts = 0
        for b in bufferinfos
            nverts_ = length(b.buffer)
            if nverts != 0 && nverts != nverts_ && b.divisor == GEOMETRY_DIVISOR
                error("Amount of vertices is not equal.")
            end
            nverts = nverts_
        end

        if indices != nothing
            bind(indices)
            nverts = length(indices) * cardinality(indices)
        end

        attach2vao.(bufferinfos)

        glBindVertexArray(0)
        if length(bufferinfos) == 1
            if !is_glsl_primitive(eltype(bufferinfos[1].buffer))
                vert_type = eltype(bufferinfos[1].buffer)
            else
                vert_type = Tuple{eltype(bufferinfos[1].buffer)}
            end
        else
            vert_type = Tuple{eltype.(bufferinfos)...}
        end
        obj = new{vert_type, kind}(id, bufferinfos, indices, nverts, ninst, face, current_context())
        finalizer(free!, obj)
        obj
    end
    function VertexArray()
	    return new{Nothing, EMPTY}(GLuint(0),
	                               Buffer[],
	                               nothing,
	                               GLint(0),
	                               GLint(0),
	                               GL_POINTS,
	                               current_context())
	end
end

VertexArray(bufferinfos::Vector{<:BufferAttachmentInfo}, face::GLenum=GL_TRIANGLES) =
    VertexArray(SIMPLE, bufferinfos, nothing, 1, face)

VertexArray(bufferinfos::Vector{<:BufferAttachmentInfo}, indices::Vector{<:Integer}, face::GLenum) =
    VertexArray(ELEMENTS, bufferinfos, indexbuffer(GLint.(indices)), 1, face)

#TODO this is messy
VertexArray(bufferinfos::Vector{<:BufferAttachmentInfo}, indices::Vector{F}; facelength=F) where F =
    VertexArray(ELEMENTS, bufferinfos, indexbuffer(indices), 1, face2glenum(facelength))

VertexArray(bufferinfos::Vector{<:BufferAttachmentInfo}, indices::Vector{<:Integer}, facelength::Union{GLenum, Int}, ninst::Int) =
    VertexArray(ELEMENTS_INSTANCED, bufferinfos, indexbuffer(GLint.(indices)), ninst, face2glenum(facelength))

VertexArray(bufferinfos::Vector{<:BufferAttachmentInfo}, indices::Vector{F}, ninst::Int) where F =
    VertexArray(ELEMENTS_INSTANCED, bufferinfos, indexbuffer(indices), ninst, face2glenum(F))

free!(x::VertexArray) =
    context_command(() -> glDeleteVertexArrays(1, [x.id]), x.context)
    
is_null(vao::VertexArray{Nothing, EMPTY}) = true
is_null(vao::VertexArray)                 = false

bufferinfo(vao::VertexArray, name::Symbol) = (id =findfirst(x->x.name == name, vao.bufferinfos); id !== nothing ? vao.bufferinfos[id] : id)

# the instanced ones assume that there is at least one buffer with the vertextype (=has fields, bit whishy washy) and the others are the instanced things
# It is assumed that when an attribute is longer than 4 bytes, the rest is stored in consecutive locations
function attach2vao(bufferinfo::BufferAttachmentInfo{T}) where T

    function enable_attrib(loc)
        glEnableVertexAttribArray(loc)
        if bufferinfo.divisor != GEOMETRY_DIVISOR
            glVertexAttribDivisor(loc, bufferinfo.divisor)
        end
    end

    bind(bufferinfo.buffer)
    if !is_glsl_primitive(T)
        # This is for a buffer that holds all the attributes in a OpenGL defined way.
        # This requires us to find the fieldoffset
        # TODO this is not tested
        for i = 1:nfields(T)
            loc = bufferinfo.location + i - 1
            FT = fieldtype(T, i); ET = eltype(FT)
            glVertexAttribPointer(loc,
                                  cardinality(FT), julia2glenum(ET),
                                  GL_FALSE, sizeof(T), Ptr{Nothing}(fieldoffset(T, i)))
            enable_attrib(loc)
        end
    else
        # This is for when the buffer holds a single attribute, no need to
        # calculate fieldoffsets and stuff like that.
        # TODO Assumes everything larger than vec4 is a matrix, is this ok?
        FT = T; ET = eltype(FT)
        cardi = cardinality(FT)
        gltype = julia2glenum(ET)
        if cardi > 4
            s = size(FT)
            loc_size = s[2]
            for li=0:s[1]-1
                loc = bufferinfo.location + li
                offset = sizeof(gltype) * loc_size * li
                glVertexAttribPointer(loc, loc_size, gltype, GL_FALSE, cardi*sizeof(gltype), Ptr{Nothing}(offset))
                enable_attrib(loc)
            end
        else
            glVertexAttribPointer(bufferinfo.location, cardi, gltype, GL_FALSE, 0, C_NULL)
            enable_attrib(bufferinfo.location)
        end
    end
end

# TODO
Base.convert(::Type{VertexArray}, x) = VertexArray(x)
Base.convert(::Type{VertexArray}, x::VertexArray) = x

function face2glenum(face)
    facelength = typeof(face) <: Integer ? face : (face <: Integer ? 1 : length(face))
    facelength == 1  && return GL_POINTS
    facelength == 2  && return GL_LINES
    facelength == 3  && return GL_TRIANGLES
    facelength == 4  && return GL_QUADS
    facelength == 5  && return GL_TRIANGLE_STRIP
    facelength == 10 && return GL_LINES_ADJACENCY
    facelength == 11 && return GL_LINE_STRIP_ADJACENCY
    return GL_TRIANGLES
end

function glenum2face(glenum)
    glenum == GL_POINTS               && return 1
    glenum == GL_LINES                && return 2
    glenum == GL_TRIANGLES            && return 3
    glenum == GL_QUADS                && return 4
    glenum == GL_TRIANGLE_STRIP       && return 5
    glenum == GL_LINES_ADJACENCY      && return 10
    glenum == GL_LINE_STRIP_ADJACENCY && return 11
    return 1
end

is_struct(::Type{T}) where T = !(sizeof(T) != 0 && nfields(T) == 0)
# is_glsl_primitive{T <: StaticVector}(::Type{T}) = true
is_glsl_primitive(::Type{T}) where {T <: Union{Float32, Int32}}= true
function is_glsl_primitive(T)
    glasserteltype(T)
    true
end

_typeof(::Type{T}) where T = Type{T}
_typeof(::T) where T = T


glitype(vao::VertexArray) = julia2glenum(eltype(vao.indices))

Base.length(vao::VertexArray) = vao.nverts

bind(vao::VertexArray) = glBindVertexArray(vao.id)
unbind(vao::VertexArray) = glBindVertexArray(0)

#does this ever work with anything aside from an unsigned int??
draw(vao::VertexArray{V, ELEMENTS} where V) = glDrawElements(vao.face, vao.nverts, GL_UNSIGNED_INT, C_NULL)

draw(vao::VertexArray{V, ELEMENTS_INSTANCED} where V) = glDrawElementsInstanced(vao.face, vao.nverts, GL_UNSIGNED_INT, C_NULL, vao.ninst)

draw(vao::VertexArray{V, SIMPLE} where V) = glDrawArrays(vao.face, 0, vao.nverts)

function Base.show(io::IO, vao::T) where T<:VertexArray
    fields = filter(x->x != :buffers && x!=:indices, [fieldnames(T)...])
    for field in fields
        show(io, getfield(vao, field))
        println(io,"")
    end
end

Base.eltype(::Type{VertexArray{ElTypes, Kind}}) where {ElTypes, Kind} = (ElTypes, Kind)

#This could also be done just with the symbols, not needing new bufferattachment infos
function upload!(vao::VertexArray; name_buffers...)
    for (n, b) in name_buffers
        existing_b = findfirst(x -> x.name == n, vao.bufferinfos)
        upload_data!(vao.bufferinfos[existing_b].buffer, b)
    end
end




