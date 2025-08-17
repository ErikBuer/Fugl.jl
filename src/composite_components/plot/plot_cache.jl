# GPU cache for plot rendering
mutable struct PlotCache
    framebuffer::Union{UInt32,Nothing}     # OpenGL framebuffer object
    color_texture::Union{UInt32,Nothing}   # Color texture
    depth_texture::Union{UInt32,Nothing}   # Depth texture (if needed)
    cache_width::Int32                      # Cached framebuffer width
    cache_height::Int32                     # Cached framebuffer height
    is_valid::Bool                          # Whether cache is valid

    # Cache invalidation tracking
    last_elements_hash::UInt64              # Hash of elements for change detection
    last_state_hash::UInt64                 # Hash of plot state for change detection
    last_style_hash::UInt64                 # Hash of plot style for change detection
    last_bounds::Tuple{Float32,Float32,Float32,Float32}  # Last render bounds
end

function PlotCache()
    return PlotCache(
        nothing, nothing, nothing,
        0, 0, false,
        0x0, 0x0, 0x0,
        (0.0f0, 0.0f0, 0.0f0, 0.0f0)
    )
end

# Global cache storage - maps PlotView to its cache
const _plot_caches = Dict{Any,PlotCache}()

function cleanup_plot_cache(cache::PlotCache)
    if cache.framebuffer !== nothing
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

function create_plot_framebuffer(width::Int32, height::Int32)::Tuple{UInt32,UInt32,UInt32}
    # Generate framebuffer
    framebuffer_ref = Ref{UInt32}(0)
    ModernGL.glGenFramebuffers(1, framebuffer_ref)
    framebuffer = framebuffer_ref[]
    ModernGL.glBindFramebuffer(ModernGL.GL_FRAMEBUFFER, framebuffer)

    # Create color texture
    color_texture_ref = Ref{UInt32}(0)
    ModernGL.glGenTextures(1, color_texture_ref)
    color_texture = color_texture_ref[]
    ModernGL.glBindTexture(ModernGL.GL_TEXTURE_2D, color_texture)
    ModernGL.glTexImage2D(ModernGL.GL_TEXTURE_2D, 0, ModernGL.GL_RGBA8, width, height, 0, ModernGL.GL_RGBA, ModernGL.GL_UNSIGNED_BYTE, C_NULL)
    ModernGL.glTexParameteri(ModernGL.GL_TEXTURE_2D, ModernGL.GL_TEXTURE_MIN_FILTER, ModernGL.GL_LINEAR)
    ModernGL.glTexParameteri(ModernGL.GL_TEXTURE_2D, ModernGL.GL_TEXTURE_MAG_FILTER, ModernGL.GL_LINEAR)
    ModernGL.glFramebufferTexture2D(ModernGL.GL_FRAMEBUFFER, ModernGL.GL_COLOR_ATTACHMENT0, ModernGL.GL_TEXTURE_2D, color_texture, 0)

    # Create depth texture (for proper depth testing if needed)
    depth_texture_ref = Ref{UInt32}(0)
    ModernGL.glGenTextures(1, depth_texture_ref)
    depth_texture = depth_texture_ref[]
    ModernGL.glBindTexture(ModernGL.GL_TEXTURE_2D, depth_texture)
    ModernGL.glTexImage2D(ModernGL.GL_TEXTURE_2D, 0, ModernGL.GL_DEPTH_COMPONENT24, width, height, 0, ModernGL.GL_DEPTH_COMPONENT, ModernGL.GL_FLOAT, C_NULL)
    ModernGL.glTexParameteri(ModernGL.GL_TEXTURE_2D, ModernGL.GL_TEXTURE_MIN_FILTER, ModernGL.GL_LINEAR)
    ModernGL.glTexParameteri(ModernGL.GL_TEXTURE_2D, ModernGL.GL_TEXTURE_MAG_FILTER, ModernGL.GL_LINEAR)
    ModernGL.glFramebufferTexture2D(ModernGL.GL_FRAMEBUFFER, ModernGL.GL_DEPTH_ATTACHMENT, ModernGL.GL_TEXTURE_2D, depth_texture, 0)

    # Check framebuffer completeness
    if ModernGL.glCheckFramebufferStatus(ModernGL.GL_FRAMEBUFFER) != ModernGL.GL_FRAMEBUFFER_COMPLETE
        error("Framebuffer not complete!")
    end

    # Unbind framebuffer
    ModernGL.glBindFramebuffer(ModernGL.GL_FRAMEBUFFER, 0)
    ModernGL.glBindTexture(ModernGL.GL_TEXTURE_2D, 0)

    return (framebuffer, color_texture, depth_texture)
end

function hash_plot_elements(elements::Vector{AbstractPlotElement})::UInt64
    # Create a hash based on the elements data for change detection
    h = hash(length(elements))
    for element in elements
        if element isa LinePlotElement
            h = hash((element.x_data, element.y_data, element.color, element.width, element.line_style), h)
        elseif element isa ScatterPlotElement
            h = hash((element.x_data, element.y_data, element.fill_color, element.border_color,
                    element.marker_size, element.border_width, element.marker_type), h)
        elseif element isa StemPlotElement
            h = hash((element.x_data, element.y_data, element.line_color, element.fill_color,
                    element.border_color, element.line_width, element.marker_size,
                    element.border_width, element.marker_type, element.baseline), h)
        elseif element isa ImagePlotElement
            h = hash((element.data, element.x_range, element.y_range, element.colormap), h)
        end
    end
    return h
end

function hash_plot_state(state::PlotState)::UInt64
    return hash((state.bounds, state.auto_scale,
        state.initial_x_min, state.initial_x_max, state.initial_y_min, state.initial_y_max,
        state.current_x_min, state.current_x_max, state.current_y_min, state.current_y_max))
end

function hash_plot_style(style::PlotStyle)::UInt64
    return hash((style.background_color, style.grid_color, style.axis_color,
        style.show_grid, style.show_axes, style.show_legend,
        style.padding_px, style.anti_aliasing_width))
end

function should_invalidate_cache(cache::PlotCache, view::Any, bounds::Tuple{Float32,Float32,Float32,Float32})::Bool
    # Check if cache exists and is valid
    if !cache.is_valid || cache.framebuffer === nothing
        return true
    end

    # Check if size changed
    current_width = Int32(bounds[3])
    current_height = Int32(bounds[4])
    if cache.cache_width != current_width || cache.cache_height != current_height
        return true
    end

    # Check if bounds changed
    if cache.last_bounds != bounds
        return true
    end

    # Check if elements changed
    elements_hash = hash_plot_elements(view.elements)
    if cache.last_elements_hash != elements_hash
        return true
    end

    # Check if state changed
    state_hash = hash_plot_state(view.state)
    if cache.last_state_hash != state_hash
        return true
    end

    # Check if style changed
    style_hash = hash_plot_style(view.style)
    if cache.last_style_hash != style_hash
        return true
    end

    return false
end

"""
Manually invalidate plot cache to force re-render on next frame"""
function invalidate_plot_cache!(cache::PlotCache)
    cache.is_valid = false
end

"""
Clean up plot cache for a specific cache key. Call this when a plot cache is no longer needed.
"""
function cleanup_plot_view_cache!(cache_key::Any)
    if haskey(_plot_caches, cache_key)
        cache = _plot_caches[cache_key]
        cleanup_plot_cache(cache)
        delete!(_plot_caches, cache_key)
    end
end

"""
Clean up all plot caches. Call this on application shutdown.
"""
function cleanup_all_plot_caches!()
    for (view, cache) in _plot_caches
        cleanup_plot_cache(cache)
    end
    empty!(_plot_caches)
    empty!(_drag_start_bounds)
    empty!(_drag_start_mouse_pos)
end

"""
Get cache statistics for debugging/monitoring
"""
function get_plot_cache_stats()
    total_caches = length(_plot_caches)
    valid_caches = count(cache -> cache.is_valid, values(_plot_caches))

    return (
        total_caches=total_caches,
        valid_caches=valid_caches,
        invalid_caches=total_caches - valid_caches
    )
end