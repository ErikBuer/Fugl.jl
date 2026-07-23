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
    scissor_stack::Vector{Union{Nothing,Tuple{Int32,Int32,Int32,Int32}}}  # Stack of scissor states (nothing = disabled)
    current_scissor::Union{Nothing,Tuple{Int32,Int32,Int32,Int32}}        # Current scissor state (nothing = disabled)

    GLContextState() = new(UInt32[], Set{UInt32}(), 0, Tuple{Int32,Int32,Int32,Int32}[], (0, 0, 0, 0), Union{Nothing,Tuple{Int32,Int32,Int32,Int32}}[], nothing)
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
    empty!(GL_STATE.scissor_stack)

    # Get current framebuffer binding
    current_fbo = Ref{Int32}(0)
    ModernGL.glGetIntegerv(ModernGL.GL_FRAMEBUFFER_BINDING, current_fbo)
    GL_STATE.current_framebuffer = UInt32(current_fbo[])

    # Get current viewport
    viewport = Vector{Int32}(undef, 4)
    ModernGL.glGetIntegerv(ModernGL.GL_VIEWPORT, viewport)
    GL_STATE.current_viewport = (viewport[1], viewport[2], viewport[3], viewport[4])

    # Get current scissor state
    scissor_enabled = ModernGL.glIsEnabled(ModernGL.GL_SCISSOR_TEST)
    if scissor_enabled == ModernGL.GL_TRUE
        scissor_box = Vector{Int32}(undef, 4)
        ModernGL.glGetIntegerv(ModernGL.GL_SCISSOR_BOX, scissor_box)
        GL_STATE.current_scissor = (scissor_box[1], scissor_box[2], scissor_box[3], scissor_box[4])
    else
        GL_STATE.current_scissor = nothing
    end
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
Push the current scissor rect onto the stack and set a new one, intersected with
the currently active scissor rect (if any) so nested clips can only shrink the
effective region, never grow it. All inputs/outputs are in absolute pixel space.
"""
function push_scissor!(x::Int32, y::Int32, width::Int32, height::Int32)
    push!(GL_STATE.scissor_stack, GL_STATE.current_scissor)

    previous = GL_STATE.current_scissor
    new_rect = if previous === nothing
        (x, y, width, height)
    else
        px, py, pwidth, pheight = previous
        ix = max(x, px)
        iy = max(y, py)
        iright = min(x + width, px + pwidth)
        itop = min(y + height, py + pheight)
        (ix, iy, max(Int32(0), iright - ix), max(Int32(0), itop - iy))
    end

    GL_STATE.current_scissor = new_rect
    ModernGL.glEnable(ModernGL.GL_SCISSOR_TEST)
    ModernGL.glScissor(new_rect[1], new_rect[2], new_rect[3], new_rect[4])
end

"""
Pop the previous scissor rect from the stack and restore it. If no scissor was
active before the corresponding push, disables the scissor test.
"""
function pop_scissor!()
    if !isempty(GL_STATE.scissor_stack)
        previous_scissor = pop!(GL_STATE.scissor_stack)
        GL_STATE.current_scissor = previous_scissor
        if previous_scissor === nothing
            ModernGL.glDisable(ModernGL.GL_SCISSOR_TEST)
        else
            ModernGL.glScissor(previous_scissor[1], previous_scissor[2], previous_scissor[3], previous_scissor[4])
        end
    else
        @warn "Attempting to pop from empty scissor stack"
    end
end

"""
Run `f` with a scissor clip active for `(x, y, width, height)` (absolute pixel space),
intersected with any enclosing scissor region via `push_scissor!`. The previous scissor
state is always restored afterward, even if `f` throws.

# Example
```julia
with_scissor_clip(x, y, width, height) do
    interpret_view(content, ...)
end
```
"""
function with_scissor_clip(f::Function, x::Int32, y::Int32, width::Int32, height::Int32)
    push_scissor!(x, y, width, height)
    try
        f()
    finally
        pop_scissor!()
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
Get the current scissor state (nothing if scissor testing is currently disabled)
"""
function get_current_scissor()::Union{Nothing,Tuple{Int32,Int32,Int32,Int32}}
    return GL_STATE.current_scissor
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