#TODO the current caching requires the state of the component to be user managed.
# If we derive a number for the components place in the view hierarchy, we can use caching even for components that are not user managed (state).

mutable struct RenderCache
    framebuffer::Union{UInt32,Nothing}     # OpenGL framebuffer object
    color_texture::Union{UInt32,Nothing}   # Color texture
    depth_texture::Union{UInt32,Nothing}   # Depth texture (optional)
    cache_width::Int32                      # Cached framebuffer width
    cache_height::Int32                     # Cached framebuffer height
    is_valid::Bool                          # Whether cache is valid
    last_bounds::Tuple{Float32,Float32,Float32,Float32}  # Last render bounds
    last_content_hash::UInt64               # Hash of content for change detection
    last_access::Float64                    # Timestamp of last access (for cleanup)

    RenderCache() = new(nothing, nothing, nothing, 0, 0, false, (0.0f0, 0.0f0, 0.0f0, 0.0f0), 0x0, time())
end

# Global cache storage - maps cache IDs to their caches
const _render_caches = Dict{UInt64,RenderCache}()

# Global counter for generating unique cache IDs
const _cache_id_counter = Ref{UInt64}(0)

"""
Generate a unique cache ID for a component
"""
function generate_cache_id()::UInt64
    _cache_id_counter[] += 1
    return _cache_id_counter[]
end

"""
Clean up OpenGL resources for a single cache entry
"""
function cleanup_render_cache(cache::RenderCache)
    if cache.framebuffer !== nothing
        # Unregister from tracking before deleting
        unregister_cache_framebuffer!(cache.framebuffer)
        framebuffer_ref = Ref{UInt32}(cache.framebuffer)
        ModernGL.glDeleteFramebuffers(1, framebuffer_ref)
    end
    if cache.color_texture !== nothing
        texture_ref = Ref{UInt32}(cache.color_texture)
        ModernGL.glDeleteTextures(1, texture_ref)
    end
    if cache.depth_texture !== nothing
        texture_ref = Ref{UInt32}(cache.depth_texture)
        ModernGL.glDeleteTextures(1, texture_ref)
    end
    cache.framebuffer = nothing
    cache.color_texture = nothing
    cache.depth_texture = nothing
    cache.is_valid = false
end

"""
Create a framebuffer with color and optional depth texture
Returns (framebuffer_id, color_texture_id, depth_texture_id)
"""
function create_render_framebuffer(width::Int32, height::Int32; with_depth::Bool=false)::Tuple{UInt32,UInt32,Union{UInt32,Nothing}}
    # Generate framebuffer
    framebuffer_ref = Ref{UInt32}(0)
    ModernGL.glGenFramebuffers(1, framebuffer_ref)
    framebuffer = framebuffer_ref[]

    # Push current framebuffer onto stack and bind the new one
    push_framebuffer!(framebuffer)

    # Create color texture
    color_texture_ref = Ref{UInt32}(0)
    ModernGL.glGenTextures(1, color_texture_ref)
    color_texture = color_texture_ref[]
    ModernGL.glBindTexture(ModernGL.GL_TEXTURE_2D, color_texture)
    ModernGL.glTexImage2D(ModernGL.GL_TEXTURE_2D, 0, ModernGL.GL_RGBA8, width, height, 0, ModernGL.GL_RGBA, ModernGL.GL_UNSIGNED_BYTE, C_NULL)
    ModernGL.glTexParameteri(ModernGL.GL_TEXTURE_2D, ModernGL.GL_TEXTURE_MIN_FILTER, ModernGL.GL_LINEAR)
    ModernGL.glTexParameteri(ModernGL.GL_TEXTURE_2D, ModernGL.GL_TEXTURE_MAG_FILTER, ModernGL.GL_LINEAR)
    ModernGL.glFramebufferTexture2D(ModernGL.GL_FRAMEBUFFER, ModernGL.GL_COLOR_ATTACHMENT0, ModernGL.GL_TEXTURE_2D, color_texture, 0)

    # Create depth texture if requested
    depth_texture = nothing
    if with_depth
        depth_texture_ref = Ref{UInt32}(0)
        ModernGL.glGenTextures(1, depth_texture_ref)
        depth_texture = depth_texture_ref[]
        ModernGL.glBindTexture(ModernGL.GL_TEXTURE_2D, depth_texture)
        ModernGL.glTexImage2D(ModernGL.GL_TEXTURE_2D, 0, ModernGL.GL_DEPTH_COMPONENT24, width, height, 0, ModernGL.GL_DEPTH_COMPONENT, ModernGL.GL_FLOAT, C_NULL)
        ModernGL.glTexParameteri(ModernGL.GL_TEXTURE_2D, ModernGL.GL_TEXTURE_MIN_FILTER, ModernGL.GL_LINEAR)
        ModernGL.glTexParameteri(ModernGL.GL_TEXTURE_2D, ModernGL.GL_TEXTURE_MAG_FILTER, ModernGL.GL_LINEAR)
        ModernGL.glFramebufferTexture2D(ModernGL.GL_FRAMEBUFFER, ModernGL.GL_DEPTH_ATTACHMENT, ModernGL.GL_TEXTURE_2D, depth_texture, 0)
    end

    # Check framebuffer completeness
    if ModernGL.glCheckFramebufferStatus(ModernGL.GL_FRAMEBUFFER) != ModernGL.GL_FRAMEBUFFER_COMPLETE
        error("Framebuffer not complete!")
    end

    # Register this as a cache framebuffer
    register_cache_framebuffer!(framebuffer)

    # Restore previous framebuffer binding and unbind texture
    pop_framebuffer!()
    ModernGL.glBindTexture(ModernGL.GL_TEXTURE_2D, 0)

    return (framebuffer, color_texture, depth_texture)
end

"""
Get or create a render cache for the given cache ID.
"""
function get_render_cache(cache_id::UInt64)::RenderCache
    if !haskey(_render_caches, cache_id)
        _render_caches[cache_id] = RenderCache()
    end
    cache = _render_caches[cache_id]
    cache.last_access = time()
    return cache
end

"""
Check if a framebuffer is still valid and complete
"""
function is_framebuffer_valid(framebuffer_id::UInt32)::Bool
    if framebuffer_id == 0
        return false
    end

    # Check if the framebuffer object still exists
    is_framebuffer = ModernGL.glIsFramebuffer(framebuffer_id)
    if !is_framebuffer
        return false
    end

    # Bind and check completeness
    current_fbo = Ref{Int32}(0)
    ModernGL.glGetIntegerv(ModernGL.GL_FRAMEBUFFER_BINDING, current_fbo)

    ModernGL.glBindFramebuffer(ModernGL.GL_FRAMEBUFFER, framebuffer_id)
    is_complete = ModernGL.glCheckFramebufferStatus(ModernGL.GL_FRAMEBUFFER) == ModernGL.GL_FRAMEBUFFER_COMPLETE

    # Restore previous framebuffer
    ModernGL.glBindFramebuffer(ModernGL.GL_FRAMEBUFFER, current_fbo[])

    return is_complete
end

"""
Check if a cache needs to be invalidated based on content hash and bounds.
Each component should provide its own content_hash_func that captures all
the state that affects rendering.
"""
function should_invalidate_cache(cache::RenderCache, content_hash::UInt64, bounds::Tuple{Float32,Float32,Float32,Float32})::Bool
    # Check if cache exists and is valid
    if !cache.is_valid || cache.framebuffer === nothing
        return true
    end

    # Check if framebuffer is still valid (important for window resize on macOS)
    if !is_framebuffer_valid(cache.framebuffer)
        return true
    end

    # Check if size changed
    current_width = Int32(round(bounds[3]))  # Use round() for consistent sizing
    current_height = Int32(round(bounds[4]))  # Use round() for consistent sizing
    if cache.cache_width != current_width || cache.cache_height != current_height
        return true
    end

    # Check if bounds changed (with small tolerance for floating point precision)
    bounds_tolerance = 1.0f0
    if abs(cache.last_bounds[1] - bounds[1]) > bounds_tolerance ||
       abs(cache.last_bounds[2] - bounds[2]) > bounds_tolerance ||
       abs(cache.last_bounds[3] - bounds[3]) > bounds_tolerance ||
       abs(cache.last_bounds[4] - bounds[4]) > bounds_tolerance
        return true
    end

    # Check if content changed
    if cache.last_content_hash != content_hash
        return true
    end

    return false
end

"""
Update a cache with new framebuffer, content hash, and bounds
"""
function update_cache!(cache::RenderCache, framebuffer::UInt32, color_texture::UInt32, depth_texture::Union{UInt32,Nothing},
    content_hash::UInt64, bounds::Tuple{Float32,Float32,Float32,Float32})
    # Clean up old framebuffer if it exists
    if cache.framebuffer !== nothing && cache.framebuffer != framebuffer
        cleanup_render_cache(cache)
    end

    cache.framebuffer = framebuffer
    cache.color_texture = color_texture
    cache.depth_texture = depth_texture
    cache.cache_width = Int32(round(bounds[3]))
    cache.cache_height = Int32(round(bounds[4]))
    cache.is_valid = true
    cache.last_bounds = bounds
    cache.last_content_hash = content_hash
    cache.last_access = time()
end

"""
Manually invalidate a render cache to force re-render on next frame
"""
function invalidate_render_cache!(cache::RenderCache)
    cache.is_valid = false
end

"""
Clean up render cache for a specific cache ID
"""
function cleanup_render_cache_id!(cache_id::UInt64)
    if haskey(_render_caches, cache_id)
        cache = _render_caches[cache_id]
        cleanup_render_cache(cache)
        delete!(_render_caches, cache_id)
    end
end

"""
Clear all render caches and free associated OpenGL resources.
Call this when the OpenGL context is being destroyed or recreated.
"""
function clear_render_caches!()
    for (cache_id, cache) in _render_caches
        cleanup_render_cache(cache)
    end
    empty!(_render_caches)
end

"""
Clean up old caches that haven't been accessed recently.
Call this periodically to prevent memory leaks from unused caches.
"""
function cleanup_stale_render_caches!(max_age_seconds::Float64=300.0)
    current_time = time()
    stale_ids = UInt64[]

    for (cache_id, cache) in _render_caches
        if current_time - cache.last_access > max_age_seconds
            push!(stale_ids, cache_id)
        end
    end

    for cache_id in stale_ids
        cleanup_render_cache_id!(cache_id)
    end

    if !isempty(stale_ids)
        @info "Cleaned up $(length(stale_ids)) stale render caches"
    end
end

"""
Get cache statistics for debugging/monitoring
"""
function get_render_cache_stats()
    total_caches = length(_render_caches)
    valid_caches = count(cache -> cache.is_valid, values(_render_caches))
    current_time = time()
    recent_caches = count(cache -> current_time - cache.last_access < 60.0, values(_render_caches))

    return (
        total_caches=total_caches,
        valid_caches=valid_caches,
        invalid_caches=total_caches - valid_caches,
        recent_caches=recent_caches
    )
end

"""
Draw a cached texture to screen using a simple textured quad
"""
function draw_cached_texture(texture_id::UInt32, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    # Create vertices for a quad using Point2f (same as working draw_rectangle)
    positions = Point2f[
        Point2f(x, y + height),                # Top-left
        Point2f(x, y),                         # Bottom-left  
        Point2f(x + width, y),                 # Bottom-right
        Point2f(x + width, y + height)         # Top-right
    ]

    # Texture coordinates matching vertex order
    texturecoordinates = Vec2{Float32}[
        Vec2{Float32}(0.0f0, 0.0f0),  # Top-left
        Vec2{Float32}(0.0f0, 1.0f0),  # Bottom-left
        Vec2{Float32}(1.0f0, 1.0f0),  # Bottom-right
        Vec2{Float32}(1.0f0, 0.0f0)   # Top-right
    ]

    # White color for all vertices (texture will override)
    colors = Vec4{Float32}[Vec4{Float32}(1.0f0, 1.0f0, 1.0f0, 1.0f0) for _ in 1:4]

    # Define the elements (two triangles forming the rectangle) - same as working draw_rectangle
    elements = NgonFace{3,UInt32}[
        (0, 1, 2),  # First triangle: top-left, bottom-left, bottom-right
        (2, 3, 0)   # Second triangle: bottom-right, top-right, top-left
    ]

    # Generate buffers for positions, texture coordinates, and colors
    buffers = GLA.generate_buffers(prog[], position=positions, texcoord=texturecoordinates, color=colors)

    # Create a Vertex Array Object (VAO) with the elements
    vao = GLA.VertexArray(buffers, elements)

    # Bind the shader program
    GLA.bind(prog[])

    # Set uniforms
    GLA.gluniform(prog[], :use_texture, true)
    ModernGL.glActiveTexture(ModernGL.GL_TEXTURE0)
    ModernGL.glBindTexture(ModernGL.GL_TEXTURE_2D, texture_id)
    GLA.gluniform(prog[], :image, Int32(0))
    GLA.gluniform(prog[], :projection, projection_matrix)

    # Draw the quad
    GLA.bind(vao)
    GLA.draw(vao)

    # Cleanup
    GLA.unbind(vao)
    GLA.unbind(prog[])
    ModernGL.glBindTexture(ModernGL.GL_TEXTURE_2D, 0)
end
