GL_COLOR_ATTACHMENT(i) = GLuint(GL_COLOR_ATTACHMENT0 + i)
#TODO talk about Contexts!
"""
Holds the id, format and attachment of an OpenGL RenderBuffer.
RenderBuffers cannot be read by Shaders.
"""
mutable struct RenderBuffer
    id        ::GLuint
    format    ::GLenum
    attachment::GLenum
    context   ::Context
    size      ::Tuple{Int, Int}
    function RenderBuffer(format::GLenum, attachment::GLenum, dimensions)
        @assert length(dimensions) == 2
        id = glGenRenderbuffers(format, attachment, dimensions)
        obj = new(id, format, attachment, current_context(), dimensions)
        finalizer(free!, obj)
        obj
    end
end

"Creates a `RenderBuffer` with purpose for the `depth` component of a `FrameBuffer`."
function RenderBuffer(depth_format, dimensions)
    return RenderBuffer(gl_internal_format(depth_format), gl_attachment(depth_format), dimensions)
end

free!(rb::RenderBuffer) =
    context_command(() -> glDeleteRenderbuffers(1, [rb.id]), rb.context)

bind(b::RenderBuffer) = glBindRenderbuffer(GL_RENDERBUFFER, b.id)
unbind(b::RenderBuffer) = glBindRenderbuffer(GL_RENDERBUFFER, b.id)

Base.size(b::RenderBuffer) = b.size
width(b::RenderBuffer)  = size(b, 1)
height(b::RenderBuffer) = size(b, 2)
depth(b::RenderBuffer)  = size(b, 3) #possible need to assert

function resize_nocopy!(b::RenderBuffer, dimensions)
    bind(b)
    b.size = dimensions
    glRenderbufferStorage(GL_RENDERBUFFER, b.format, dimensions...)
end

"""
A FrameBuffer holds all the data related to the usual OpenGL FrameBufferObjects.
The `attachments` field gets mapped to the different possible GL_COLOR_ATTACHMENTs, which is bound by GL_MAX_COLOR_ATTACHMENTS,
and to one of either a GL_DEPTH_ATTACHMENT or GL_DEPTH_STENCIL_ATTACHMENT.
"""
mutable struct FrameBuffer{ElementTypes, T}
    id         ::GLuint
    attachments::T
    context    ::Context
    function FrameBuffer(fb_size::NTuple{2, Int}, attachments::Union{Texture, RenderBuffer}...; kwargs...)
        framebuffer = glGenFramebuffers()
        glBindFramebuffer(GL_FRAMEBUFFER, framebuffer)
        max_ca = glGetIntegerv(GL_MAX_COLOR_ATTACHMENTS)

        depth_attachments = Union{Texture, RenderBuffer}[]
        for (i, a) in enumerate(attachments)
            if eltype(a) <: DepthFormat
                push!(depth_attachments, a)
            else
                attach2framebuffer(a, GL_COLOR_ATTACHMENT(i-1))
            end
        end
        

        if length(depth_attachments) > 1
            error("The amount of DepthFormat types in texture types exceeds the maximum of 1.")
        end

        N = length(attachments)
        if N > max_ca
            error("The length of texture types exceeds the maximum amount of framebuffer color attachments! Found: $N, allowed: $max_ca")
        end
        
        !isempty(depth_attachments) && attach2framebuffer(depth_attachments[1])
        #this is done so it's a tuple. Not entirely sure why thats better than an
        #array?
        _attachments = (attachments...,depth_attachments...,)

        @assert glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE "FrameBuffer (id $framebuffer) with attachments $attachment_types failed to be created."
        glBindFramebuffer(GL_FRAMEBUFFER, 0)
        obj = new{Tuple{eltype.(_attachments)...}, typeof(_attachments)}(framebuffer, _attachments, current_context())
        finalizer(free!, obj)
        return obj
    end
    function FrameBuffer(::Val{0})
        obj = new{Val{0}, Vector{Nothing}}(0, [nothing])
        return obj
    end
end

# Constructor that takes care of creating the FBO with the specified types and then filling in the data
# Might be a bit stupid not to just put this into the main constructor
function FrameBuffer(fb_size::Tuple{<: Integer, <: Integer}, texture_types, texture_data::Vector{<:Matrix}; kwargs...)
	fbo = FrameBuffer(fb_size, texture_types; kwargs...)
	for (data, attachment) in zip(texture_data, fbo.attachments)
		xrange = 1:size(data)[1]
		yrange = 1:size(data)[2]
		gpu_setindex!(attachment, data, xrange, yrange)
	end
	return fbo
end

context_framebuffer() = FrameBuffer(Val(0))

function attach2framebuffer(t::Texture{T, 2}, attachment) where T
    glFramebufferTexture2D(GL_FRAMEBUFFER, attachment, GL_TEXTURE_2D, t.id, 0)
end
function attach2framebuffer(t::Texture{T, 2}) where {T <: DepthFormat}
    glFramebufferTexture2D(GL_FRAMEBUFFER, gl_attachment(T), GL_TEXTURE_2D, t.id, 0)
end
function attach2framebuffer(x::RenderBuffer)
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, x.attachment, GL_RENDERBUFFER, x.id)
end

function free!(fb::FrameBuffer)
    for attachment in fb.attachments
        free!(attachment)
    end
    context_command(fb.context, () -> glDeleteFramebuffers(1, [fb.id]))
    return
end

Base.size(fb::FrameBuffer) = size(fb.attachments[1])
width(fb::FrameBuffer)     = size(fb, 1)
height(fb::FrameBuffer)    = size(fb, 2)
depth(fb::FrameBuffer)     = size(fb, 3)

eltypes(fb::FrameBuffer{elt}) where elt                = elt.parameters
attachtypes(fb::FrameBuffer{elt, int}) where {elt,int} = int.parameters

Base.resize!(fb::FrameBuffer{Val{0}, Vector{Nothing}}, dimensions) = glViewport(0, 0, dimensions...)

function Base.resize!(fb::FrameBuffer, dimensions)
    ws = dimensions[1], dimensions[2]
    if ws != size(fb) && all(x -> x > 0, dimensions)
        dimensions = tuple(dimensions...)
        for attachment in fb.attachments
            resize_nocopy!(attachment, dimensions)
        end
    end
    nothing
end

bind(fb::FrameBuffer, target=GL_FRAMEBUFFER) = glBindFramebuffer(target, fb.id)
unbind(fb::FrameBuffer) = glBindFramebuffer(GL_FRAMEBUFFER, 0)


#I think a lot could be optimized when knowing for sure whether an FBO has depth
#or not, and where it is located. Could even just be a different type.
function draw(fb::FrameBuffer)
    ntexts = length(color_attachments(fb))
    glDrawBuffers(GLuint(ntexts), GL_COLOR_ATTACHMENT.(0:ntexts-1))
end
draw(fb::FrameBuffer, i::Int) = glDrawBuffer(GL_COLOR_ATTACHMENT.(i-1))
function draw(fb::FrameBuffer, i::AbstractUnitRange)
    ntexts = length(color_attachments(fb)[i])
    glDrawBuffers(GLuint(ntexts), GL_COLOR_ATTACHMENT.(i.-1))
end
draw(fb::FrameBuffer{Val{0}, Nothing}) = nothing


#All this is not very focussed on performance yet
function clear!(fb::FrameBuffer, color)
    glClearColor(GLfloat(color[1]), GLfloat(color[2]), GLfloat(color[3]), GLfloat(color[4]))
    draw(fb)
    glClear(GL_COLOR_BUFFER_BIT)
    fm = depthformat(fb)
    if fm <: DepthStencil
        glClear(GL_STENCIL_BUFFER_BIT)
        glClear(GL_DEPTH_BUFFER_BIT)
    elseif fm <: Depth
        glClear(GL_DEPTH_BUFFER_BIT)
    end
end
clear!(fb::FrameBuffer) = clear!(fb, (0.0, 0.0, 0.0, 0.0))
clear!(fb::FrameBuffer{Val{0}, Vector{Nothing}}) = nothing
color_attachments(fb::FrameBuffer) =
    fb.attachments[findall(x -> !(x <: DepthFormat), eltypes(fb))]

color_attachment(fb::FrameBuffer, i) =
    fb.attachments[findall(x -> !(x <: DepthFormat), eltypes(fb))[i]]

depth_attachment(fb::FrameBuffer) =
    fb.attachments[findfirst(x -> x <: DepthFormat, eltypes(fb))]

function depthformat(fb::FrameBuffer)
    id = findfirst(x -> x <: DepthFormat, eltypes(fb))
    if id != 0
        return eltypes(fb)[id]
    else
        return Void
    end
end

gpu_data(fb::FrameBuffer, i) = gpu_data(fb.attachments[i])

