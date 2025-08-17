"""
OpenGL Context State Management

This module provides a simple state management system for OpenGL contexts,
allowing for framebuffer management, caching, and tracking of current OpenGL state.
"""
mutable struct GLContextState
    framebuffer_stack::Vector{UInt32}            # Stack of framebuffer bindings
    cache_framebuffers::Set{UInt32}              # Set of framebuffers that are caches
    current_framebuffer::UInt32                  # Current bound framebuffer
    viewport_stack::Vector{Tuple{Int32,Int32,Int32,Int32}}  # Stack of viewport states (x, y, width, height)
    current_viewport::Tuple{Int32,Int32,Int32,Int32}        # Current viewport state

    GLContextState() = new(UInt32[], Set{UInt32}(), 0, Tuple{Int32,Int32,Int32,Int32}[], (0, 0, 0, 0))
end

# Global GL state tracker
const GL_STATE = GLContextState()

"""
Initialize the GL state management system
"""
function initialize_gl_state!()
    empty!(GL_STATE.framebuffer_stack)
    empty!(GL_STATE.cache_framebuffers)
    empty!(GL_STATE.viewport_stack)

    # Get current framebuffer binding
    current_fbo = Ref{Int32}(0)
    ModernGL.glGetIntegerv(ModernGL.GL_FRAMEBUFFER_BINDING, current_fbo)
    GL_STATE.current_framebuffer = UInt32(current_fbo[])

    # Get current viewport
    viewport = Vector{Int32}(undef, 4)
    ModernGL.glGetIntegerv(ModernGL.GL_VIEWPORT, viewport)
    GL_STATE.current_viewport = (viewport[1], viewport[2], viewport[3], viewport[4])
end

"""
Push the current framebuffer onto the stack and bind a new one
"""
function push_framebuffer!(new_framebuffer::UInt32)
    push!(GL_STATE.framebuffer_stack, GL_STATE.current_framebuffer)
    GL_STATE.current_framebuffer = new_framebuffer
    ModernGL.glBindFramebuffer(ModernGL.GL_FRAMEBUFFER, new_framebuffer)
end

"""
Pop the previous framebuffer from the stack and restore it
"""
function pop_framebuffer!()
    if !isempty(GL_STATE.framebuffer_stack)
        previous_framebuffer = pop!(GL_STATE.framebuffer_stack)
        GL_STATE.current_framebuffer = previous_framebuffer
        ModernGL.glBindFramebuffer(ModernGL.GL_FRAMEBUFFER, previous_framebuffer)
    else
        @warn "Attempting to pop from empty framebuffer stack"
    end
end

"""
Push the current viewport onto the stack and set a new one
"""
function push_viewport!(x::Int32, y::Int32, width::Int32, height::Int32)
    push!(GL_STATE.viewport_stack, GL_STATE.current_viewport)
    GL_STATE.current_viewport = (x, y, width, height)
    ModernGL.glViewport(x, y, width, height)
end

"""
Pop the previous viewport from the stack and restore it
"""
function pop_viewport!()
    if !isempty(GL_STATE.viewport_stack)
        previous_viewport = pop!(GL_STATE.viewport_stack)
        GL_STATE.current_viewport = previous_viewport
        ModernGL.glViewport(previous_viewport[1], previous_viewport[2], previous_viewport[3], previous_viewport[4])
    else
        @warn "Attempting to pop from empty viewport stack"
    end
end

"""
Get the current framebuffer binding
"""
function get_current_framebuffer()::UInt32
    return GL_STATE.current_framebuffer
end

"""
Get the current viewport state
"""
function get_current_viewport()::Tuple{Int32,Int32,Int32,Int32}
    return GL_STATE.current_viewport
end

"""
Check if a framebuffer is a cache framebuffer
"""
function is_cache_framebuffer(framebuffer::UInt32)::Bool
    return framebuffer in GL_STATE.cache_framebuffers
end

"""
Register a framebuffer as a cache framebuffer
"""
function register_cache_framebuffer!(framebuffer::UInt32)
    push!(GL_STATE.cache_framebuffers, framebuffer)
end

"""
Cleanup function to remove framebuffer from tracking when deleted
"""
function unregister_cache_framebuffer!(framebuffer::UInt32)
    delete!(GL_STATE.cache_framebuffers, framebuffer)
end