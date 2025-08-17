"""
Generate a content hash for a plot that captures all rendering-relevant state
"""
function hash_plot_content(elements::Vector{AbstractPlotElement}, state::PlotState, style::PlotStyle)::UInt64
    h = hash(length(elements))

    # Hash elements data
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

    # Hash plot state
    h = hash((state.bounds, state.auto_scale,
            state.initial_x_min, state.initial_x_max, state.initial_y_min, state.initial_y_max,
            state.current_x_min, state.current_x_max, state.current_y_min, state.current_y_max), h)

    # Hash plot style
    h = hash((style.background_color, style.grid_color, style.axis_color,
            style.show_grid, style.show_axes, style.show_legend,
            style.padding_px, style.anti_aliasing_width), h)

    return h
end

"""
Check if plot cache should be invalidated
"""
function should_invalidate_plot_cache(view::PlotView, bounds::Tuple{Float32,Float32,Float32,Float32})::Bool
    # Generate content hash for the plot
    content_hash = hash_plot_content(view.elements, view.state, view.style)

    # Create cache key based on elements and style (stable across state changes)
    elements_hash = hash(view.elements)
    style_hash = hash(view.style)
    cache_key = (elements_hash, style_hash)

    # Get the cache
    cache = get_render_cache(cache_key)

    # Use generic cache invalidation logic
    return should_invalidate_cache(cache, content_hash, bounds)
end

"""
Get plot render cache using a stable cache key
"""
function get_plot_render_cache(view::PlotView)::Tuple{Any,RenderCache}
    # Create cache key based on elements and style (stable across state changes)
    elements_hash = hash(view.elements)
    style_hash = hash(view.style)
    cache_key = (elements_hash, style_hash)

    cache = get_render_cache(cache_key)
    return cache_key, cache
end

"""
Create framebuffer for plot rendering (with depth for 3D plots in future)
"""
function create_plot_framebuffer(width::Int32, height::Int32)::Tuple{UInt32,UInt32,Union{UInt32,Nothing}}
    return create_render_framebuffer(width, height; with_depth=false)
end

"""
Clear all plot caches - wrapper for the generic system
"""
function clear_plot_caches!()
    clear_render_caches!()
end

"""
Manually invalidate plot cache to force re-render on next frame
"""
function invalidate_plot_cache!(cache::RenderCache)
    invalidate_render_cache!(cache)
end