"""
Check if plot cache should be invalidated based on content changes or bounds changes
"""
function should_invalidate_plot_cache(view::PlotView, bounds::Tuple{Float32,Float32,Float32,Float32})::Bool
    # Generate content hash for the plot
    content_hash = hash_plot_content(view.elements, view.state, view.style)

    # Get the cache using the state's cache ID
    cache = get_render_cache(view.state.cache_id)

    # Use generic cache invalidation logic
    return should_invalidate_cache(cache, content_hash, bounds)
end

"""
Generate a content hash for all rendering-relevant state
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
        elseif element isa HeatmapElement
            h = hash((element.data, element.x_range, element.y_range, element.colormap), h)
        end
    end

    # Hash plot state
    h = hash((state.bounds, state.auto_scale,
            state.initial_x_min, state.initial_x_max, state.initial_y_min, state.initial_y_max,
            state.current_x_min, state.current_x_max, state.current_y_min, state.current_y_max), h)

    # Hash plot style
    h = hash((style.background_color, style.grid_color, style.axis_color,
            style.show_grid, style.show_left_axis, style.show_right_axis,
            style.show_top_axis, style.show_bottom_axis,
            style.show_x_ticks, style.show_y_ticks, style.show_legend,
            style.padding, style.anti_aliasing_width), h)

    return h
end