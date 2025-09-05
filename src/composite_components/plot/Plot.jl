abstract type AbstractPlotElement end

include("utilities.jl")
include("line_style.jl")
include("plot_style.jl")
include("plot_state.jl")
include("shaders.jl")
include("draw/line_draw.jl")
include("draw/marker_draw.jl")
include("draw/texture_draw.jl")

include("elements/line_plot.jl")
include("elements/scatter_plot.jl")
include("elements/stem_plot.jl")
include("elements/heatmap.jl")
include("elements/colorbar.jl")

struct PlotView <: AbstractView
    elements::Vector{AbstractPlotElement}
    state::PlotState
    style::PlotStyle
    on_state_change::Function
end

include("plot_cache.jl")

"""
Plot component.
"""
function Plot(
    elements::Vector{<:AbstractPlotElement},
    style::PlotStyle=PlotStyle(),
    state::PlotState=PlotState(),
    on_state_change::Function=(new_state) -> nothing
)::PlotView
    # If state has default bounds and auto_scale is true, calculate bounds from elements
    if state.bounds == Rect2f(0.0f0, 0.0f0, 1.0f0, 1.0f0) && state.auto_scale && !isempty(elements)
        calculated_bounds = calculate_bounds_from_elements(Vector{AbstractPlotElement}(elements))
        state = PlotState(calculated_bounds, state.auto_scale, state.initial_x_min, state.initial_x_max, state.initial_y_min, state.initial_y_max, state.current_x_min, state.current_x_max, state.current_y_min, state.current_y_max, state.cache_id)
    end
    return PlotView(elements, state, style, on_state_change)
end

function measure(view::PlotView)::Tuple{Float32,Float32}
    # Default: take all available space
    return (Inf32, Inf32)
end

function apply_layout(view::PlotView, x::Float32, y::Float32, width::Float32, height::Float32)
    return (x, y, width, height)
end

function interpret_view(view::PlotView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    bounds = (x, y, width, height)
    cache_width = Int32(round(width))
    cache_height = Int32(round(height))

    # Ensure minimum cache size to avoid zero-sized framebuffers
    if cache_width <= 0 || cache_height <= 0
        return  # Skip rendering if size is invalid
    end

    # Get plot render cache using state's cache ID
    cache = get_render_cache(view.state.cache_id)

    # Generate content hash for this plot
    content_hash = hash_plot_content(view.elements, view.state, view.style)

    # Check if we need to invalidate cache
    needs_redraw = should_invalidate_cache(cache, content_hash, bounds)

    # TODO: the below section seems to be overly complicated, and can likelybe simplified and made more readable.
    # See comparable code in Tree and Textbox/CodeEditor
    if needs_redraw || !cache.is_valid
        if cache.framebuffer === nothing || cache.cache_width != cache_width || cache.cache_height != cache_height
            (framebuffer, color_texture, depth_texture) = create_render_framebuffer(cache_width, cache_height; with_depth=false)

            # Update cache with new framebuffer and content hash
            update_cache!(cache, framebuffer, color_texture, depth_texture, content_hash, bounds)
        else
            # Update cache with existing framebuffer and new content hash
            update_cache!(cache, cache.framebuffer, cache.color_texture, cache.depth_texture, content_hash, bounds)
        end

        # Render to framebuffer
        render_plot_to_framebuffer(view, cache, width, height, projection_matrix)
    end

    if cache.is_valid && cache.color_texture !== nothing && cache_width > 0 && cache_height > 0 # TODO this seems to be the same check as above
        draw_cached_texture(cache.color_texture, x, y, width, height, projection_matrix)
    end
end

function render_plot_to_framebuffer(view::PlotView, cache::RenderCache, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    state = view.state
    style = view.style
    elements = view.elements

    # Push current framebuffer and viewport onto stacks
    push_framebuffer!(cache.framebuffer)
    push_viewport!(Int32(0), Int32(0), cache.cache_width, cache.cache_height)

    try
        # Clear framebuffer
        ModernGL.glClearColor(style.background_color[1], style.background_color[2], style.background_color[3], style.background_color[4])
        ModernGL.glClear(ModernGL.GL_COLOR_BUFFER_BIT | ModernGL.GL_DEPTH_BUFFER_BIT)

        # Create framebuffer-specific projection matrix
        fb_projection = get_orthographic_matrix(0.0f0, width, height, 0.0f0, -1.0f0, 1.0f0)

        # Render plot content to framebuffer
        render_plot_content(view, 0.0f0, 0.0f0, width, height, fb_projection)
    finally
        # Always restore previous framebuffer and viewport, even if there's an exception
        pop_viewport!()
        pop_framebuffer!()
    end
end

function render_plot_content(view::PlotView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    state = view.state
    style = view.style
    elements = view.elements

    # Calculate plot area (subtract padding)
    plot_x = x + style.padding
    plot_y = y + style.padding
    plot_width = width - 2 * style.padding
    plot_height = height - 2 * style.padding

    if plot_width <= 0 || plot_height <= 0 || isempty(elements)
        return  # Not enough space or no data to draw
    end

    # Transform data coordinates to screen coordinates
    function data_to_screen(data_x::Float32, data_y::Float32)::Tuple{Float32,Float32}
        # Map from effective bounds (considering zoom state) to plot area
        effective_bounds = get_effective_bounds(state)
        norm_x = (data_x - effective_bounds.x) / effective_bounds.width
        norm_y = (data_y - effective_bounds.y) / effective_bounds.height

        screen_x = plot_x + norm_x * plot_width
        screen_y = plot_y + (1.0f0 - norm_y) * plot_height  # Flip Y axis

        return (screen_x, screen_y)
    end

    # Draw grid if enabled
    if style.show_grid
        effective_bounds = get_effective_bounds(state)
        x_ticks = generate_tick_positions(effective_bounds.x, effective_bounds.x + effective_bounds.width)
        y_ticks = generate_tick_positions(effective_bounds.y, effective_bounds.y + effective_bounds.height)
        screen_bounds = Rect2f(x, y, width, height)

        draw_grid(
            effective_bounds,
            x_ticks,
            y_ticks,
            data_to_screen,
            style.grid_color,
            style.grid_width,
            DOT,  # DOT line style for grid
            projection_matrix;
            anti_aliasing_width=style.anti_aliasing_width
        )
    end

    # Draw axes and ticks if enabled
    if style.show_left_axis || style.show_right_axis || style.show_top_axis || style.show_bottom_axis || style.show_x_ticks || style.show_y_ticks
        effective_bounds = get_effective_bounds(state)
        x_ticks = generate_tick_positions(effective_bounds.x, effective_bounds.x + effective_bounds.width)
        y_ticks = generate_tick_positions(effective_bounds.y, effective_bounds.y + effective_bounds.height)
        screen_bounds = Rect2f(x, y, width, height)

        draw_axes_with_labels(
            effective_bounds,
            x_ticks,
            y_ticks,
            data_to_screen,
            screen_bounds,
            style.axis_color,
            4.0f0,  # Axis line width
            projection_matrix;
            label_color=style.axis_color,
            axis_color=style.axis_color,
            label_offset_px=5.0f0,
            tick_length_px=8.0f0,
            anti_aliasing_width=style.anti_aliasing_width,
            show_left_axis=style.show_left_axis,
            show_right_axis=style.show_right_axis,
            show_top_axis=style.show_top_axis,
            show_bottom_axis=style.show_bottom_axis,
            show_x_tick_marks=style.show_x_tick_marks,
            show_y_tick_marks=style.show_y_tick_marks,
            show_x_tick_labels=style.show_x_tick_labels,
            show_y_tick_labels=style.show_y_tick_labels,
            x_label=style.x_label,
            y_label=style.y_label,
            show_x_label=style.show_x_label,
            show_y_label=style.show_y_label
        )
    end

    # Draw plot elements with intelligent viewport culling (no scissor test)
    # Get effective bounds for data culling
    effective_bounds = get_effective_bounds(state)

    for element in elements
        draw_plot_element_culled(element, data_to_screen, projection_matrix, style, effective_bounds)
    end
end

# Drawing functions for different plot element types with viewport culling
function draw_plot_element_culled(element::LinePlotElement, data_to_screen::Function, projection_matrix::Mat4{Float32}, style::PlotStyle, effective_bounds::Rect2f)
    if length(element.x_data) >= 2 && length(element.y_data) >= 2
        # Use a small margin for data culling to include points just outside viewport
        # but clip lines to exact axis bounds
        margin_x = effective_bounds.width * 0.01f0  # 1% margin for data selection
        margin_y = effective_bounds.height * 0.01f0

        culled_x, culled_y = cull_line_data(
            element.x_data,
            element.y_data,
            effective_bounds.x - margin_x,           # Use margin for data selection
            effective_bounds.x + effective_bounds.width + margin_x,
            effective_bounds.y - margin_y,
            effective_bounds.y + effective_bounds.height + margin_y
        )

        # Now clip the selected data to exact axis bounds (no margin)
        if length(culled_x) >= 2
            final_x, final_y = cull_line_data(
                culled_x,
                culled_y,
                effective_bounds.x,                  # Exact bounds for final clipping
                effective_bounds.x + effective_bounds.width,
                effective_bounds.y,
                effective_bounds.y + effective_bounds.height
            )

            if length(final_x) >= 2
                draw_line_plot(
                    final_x,
                    final_y,
                    data_to_screen,
                    element.color,
                    element.width,
                    element.line_style,
                    projection_matrix;
                    anti_aliasing_width=style.anti_aliasing_width
                )
            end
        end
    end
end

function draw_plot_element_culled(element::ScatterPlotElement, data_to_screen::Function, projection_matrix::Mat4{Float32}, style::PlotStyle, effective_bounds::Rect2f)
    if length(element.x_data) >= 1 && length(element.y_data) >= 1
        # Use margin for data selection but exact bounds for final culling
        margin_x = effective_bounds.width * 0.02f0  # 2% margin for markers
        margin_y = effective_bounds.height * 0.02f0

        # First pass: select points with margin to capture markers near edges
        culled_x, culled_y = cull_point_data(
            element.x_data,
            element.y_data,
            effective_bounds.x - margin_x,
            effective_bounds.x + effective_bounds.width + margin_x,
            effective_bounds.y - margin_y,
            effective_bounds.y + effective_bounds.height + margin_y
        )

        # Second pass: final culling to exact bounds for precise clipping
        if length(culled_x) >= 1
            final_x, final_y = cull_point_data(
                culled_x,
                culled_y,
                effective_bounds.x,
                effective_bounds.x + effective_bounds.width,
                effective_bounds.y,
                effective_bounds.y + effective_bounds.height
            )

            if length(final_x) >= 1
                draw_scatter_plot(
                    final_x,
                    final_y,
                    data_to_screen,
                    element.fill_color,
                    element.border_color,
                    element.marker_size,
                    element.border_width,
                    element.marker_type,
                    projection_matrix;
                    anti_aliasing_width=style.anti_aliasing_width
                )
            end
        end
    end
end

function draw_plot_element_culled(element::StemPlotElement, data_to_screen::Function, projection_matrix::Mat4{Float32}, style::PlotStyle, effective_bounds::Rect2f)
    if length(element.x_data) >= 1 && length(element.y_data) >= 1
        # Use margin for data selection but exact bounds for final culling
        margin_x = effective_bounds.width * 0.02f0
        margin_y = effective_bounds.height * 0.02f0

        # First pass: select points with margin
        culled_x, culled_y = cull_point_data(
            element.x_data,
            element.y_data,
            effective_bounds.x - margin_x,
            effective_bounds.x + effective_bounds.width + margin_x,
            effective_bounds.y - margin_y,
            effective_bounds.y + effective_bounds.height + margin_y
        )

        # Second pass: final culling to exact bounds
        if length(culled_x) >= 1
            final_x, final_y = cull_point_data(
                culled_x,
                culled_y,
                effective_bounds.x,
                effective_bounds.x + effective_bounds.width,
                effective_bounds.y,
                effective_bounds.y + effective_bounds.height
            )

            if length(final_x) >= 1
                # Clamp baseline to visible Y bounds to avoid drawing outside plot area
                clipped_baseline = clamp(element.baseline, effective_bounds.y, effective_bounds.y + effective_bounds.height)

                # Batch all stem lines into a single draw call for performance
                # Each stem is represented as two points: baseline and data point
                # We'll use NaN values to separate individual stems
                batched_x = Float32[]
                batched_y = Float32[]

                for i in 1:length(final_x)
                    x_val = final_x[i]
                    y_val = final_y[i]

                    # Only include the stem if the data point and clipped baseline are different
                    if abs(clipped_baseline - y_val) > 1e-6  # Avoid drawing zero-length lines
                        # Add stem line points
                        push!(batched_x, x_val)
                        push!(batched_y, clipped_baseline)
                        push!(batched_x, x_val)
                        push!(batched_y, y_val)

                        # Add NaN separator to break the line between stems
                        if i < length(final_x)
                            push!(batched_x, NaN32)
                            push!(batched_y, NaN32)
                        end
                    end
                end

                # Draw all stems in a single batched call
                if length(batched_x) >= 2
                    # Clip the entire batched line data to exact bounds
                    stem_clipped_x, stem_clipped_y = cull_line_data(
                        batched_x,
                        batched_y,
                        effective_bounds.x,
                        effective_bounds.x + effective_bounds.width,
                        effective_bounds.y,
                        effective_bounds.y + effective_bounds.height
                    )

                    if length(stem_clipped_x) >= 2
                        draw_line_plot(
                            stem_clipped_x,
                            stem_clipped_y,
                            data_to_screen,
                            element.line_color,
                            element.line_width,
                            SOLID,  # SOLID line style
                            projection_matrix;
                            anti_aliasing_width=style.anti_aliasing_width
                        )
                    end
                end

                # Draw markers at data points (only for visible points)
                draw_scatter_plot(
                    final_x,
                    final_y,
                    data_to_screen,
                    element.fill_color,
                    element.border_color,
                    element.marker_size,
                    element.border_width,
                    element.marker_type,
                    projection_matrix;
                    anti_aliasing_width=style.anti_aliasing_width
                )
            end
        end
    end
end

function draw_plot_element_culled(element::HeatmapElement, data_to_screen::Function, projection_matrix::Mat4{Float32}, style::PlotStyle, effective_bounds::Rect2f)
    # Check if image overlaps with viewport
    x_min, x_max = element.x_range
    y_min, y_max = element.y_range

    # Simple bounds check - if image completely outside viewport, skip
    if x_max < effective_bounds.x || x_min > effective_bounds.x + effective_bounds.width ||
       y_max < effective_bounds.y || y_min > effective_bounds.y + effective_bounds.height
        return  # Image is completely outside viewport
    end

    # Draw the image plot with clipping bounds
    draw_image_plot_clipped(
        element,
        data_to_screen,
        projection_matrix,
        effective_bounds;
        anti_aliasing_width=style.anti_aliasing_width
    )
end

function draw_plot_element_culled(element::VerticalColorbar, data_to_screen::Function, projection_matrix::Mat4{Float32}, style::PlotStyle, effective_bounds::Rect2f)
    # For vertical colorbar, use the full height and the value range
    min_val, max_val = element.value_range

    # Define the colorbar data coordinate bounds that will be mapped via data_to_screen
    # For vertical: thin width (0-1), height matches value range (min_val to max_val)
    colorbar_x_min = 0.0f0
    colorbar_x_max = 1.0f0
    colorbar_y_min = min_val
    colorbar_y_max = max_val

    # Draw the colorbar gradient using the proper data coordinate system
    draw_colorbar_gradient(element, :vertical,
        colorbar_x_min, colorbar_y_min, colorbar_x_max, colorbar_y_max,
        data_to_screen, projection_matrix, effective_bounds)
end

function draw_plot_element_culled(element::HorizontalColorbar, data_to_screen::Function, projection_matrix::Mat4{Float32}, style::PlotStyle, effective_bounds::Rect2f)
    # For horizontal colorbar, use the full width and the value range
    min_val, max_val = element.value_range

    # Define the colorbar data coordinate bounds that will be mapped via data_to_screen
    # For horizontal: width matches value range (min_val to max_val), thin height (0-1)
    colorbar_x_min = min_val
    colorbar_x_max = max_val
    colorbar_y_min = 0.0f0
    colorbar_y_max = 1.0f0

    # Draw the colorbar gradient using the proper data coordinate system
    draw_colorbar_gradient(element, :horizontal,
        colorbar_x_min, colorbar_y_min, colorbar_x_max, colorbar_y_max,
        data_to_screen, projection_matrix, effective_bounds)
end

function detect_click(view::PlotView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32)
    # Get plot render cache using state's cache ID
    cache = get_render_cache(view.state.cache_id)
    interaction_occurred = false

    # Check for scroll wheel zoom with Ctrl/Cmd modifier
    if (mouse_state.scroll_y != 0.0) && is_command_key(mouse_state.modifier_keys)
        # Get mouse position relative to plot area
        mouse_x = Float32(mouse_state.x) - x
        mouse_y = Float32(mouse_state.y) - y

        # Check if mouse is within plot bounds
        if mouse_x >= 0 && mouse_x <= width && mouse_y >= 0 && mouse_y <= height
            handle_scroll_zoom(view, mouse_x, mouse_y, width, height, Float32(mouse_state.scroll_y))
            interaction_occurred = true
        end
    end

    # Check for middle mouse button drag (pan functionality)
    if mouse_state.button_state[MiddleButton] == IsPressed && mouse_state.is_dragging[MiddleButton]
        # Get mouse position relative to plot area
        mouse_x = Float32(mouse_state.x) - x
        mouse_y = Float32(mouse_state.y) - y

        # Check if mouse is within plot bounds
        if mouse_x >= 0 && mouse_x <= width && mouse_y >= 0 && mouse_y <= height && mouse_state.drag_start_position[MiddleButton] !== nothing
            handle_middle_button_drag(view, mouse_state, x, y, width, height)
            interaction_occurred = true
        end
    end

    return
end

function handle_scroll_zoom(view::PlotView, mouse_x::Float32, mouse_y::Float32, plot_width::Float32, plot_height::Float32, scroll_y::Float32)
    # Determine zoom factor based on scroll direction
    zoom_factor = scroll_y > 0 ? 0.9f0 : 1.1f0  # Scroll up = zoom in, scroll down = zoom out

    # Get current plot bounds or use auto-calculated bounds
    current_state = view.state

    # If we don't have current bounds set, calculate them from data
    if isnothing(current_state.current_x_min) || isnothing(current_state.current_x_max) ||
       isnothing(current_state.current_y_min) || isnothing(current_state.current_y_max)
        # Calculate bounds from plot elements
        if !isempty(view.elements)
            all_bounds = [get_element_bounds(element) for element in view.elements]
            min_x = minimum(bounds[1] for bounds in all_bounds)
            max_x = maximum(bounds[2] for bounds in all_bounds)
            min_y = minimum(bounds[3] for bounds in all_bounds)
            max_y = maximum(bounds[4] for bounds in all_bounds)
        else
            min_x, max_x, min_y, max_y = 0.0f0, 1.0f0, 0.0f0, 1.0f0
        end
    else
        min_x = current_state.current_x_min
        max_x = current_state.current_x_max
        min_y = current_state.current_y_min
        max_y = current_state.current_y_max
    end

    # Convert mouse position to data coordinates
    x_range = max_x - min_x
    y_range = max_y - min_y

    mouse_data_x = min_x + (mouse_x / plot_width) * x_range
    mouse_data_y = max_y - (mouse_y / plot_height) * y_range  # Flip Y coordinate

    # Calculate new bounds centered around mouse position
    new_x_range = x_range * zoom_factor
    new_y_range = y_range * zoom_factor

    new_min_x = mouse_data_x - (mouse_data_x - min_x) * zoom_factor
    new_max_x = mouse_data_x + (max_x - mouse_data_x) * zoom_factor
    new_min_y = mouse_data_y - (mouse_data_y - min_y) * zoom_factor
    new_max_y = mouse_data_y + (max_y - mouse_data_y) * zoom_factor

    new_state = PlotState(current_state;
        current_x_min=new_min_x,
        current_x_max=new_max_x,
        current_y_min=new_min_y,
        current_y_max=new_max_y,
        auto_scale=false  # Disable auto_scale when user zooms
    )

    # Notify callback for state management - user must handle updating the PlotView
    view.on_state_change(new_state)
end

function handle_middle_button_drag(view::PlotView, mouse_state::InputState, plot_x::Float32, plot_y::Float32, plot_width::Float32, plot_height::Float32)
    # Get current plot state
    current_state = view.state

    # Calculate drag movement using InputState
    if isnothing(mouse_state.last_drag_position[MiddleButton])
        return  # No valid drag positions
    end

    # Get drag positions relative to plot area
    drag_start = mouse_state.last_drag_position[MiddleButton]
    current_mouse = (Float32(mouse_state.x), Float32(mouse_state.y))

    start_x_screen = Float32(drag_start[1]) - plot_x
    start_y_screen = Float32(drag_start[2]) - plot_y
    current_x_screen = current_mouse[1] - plot_x
    current_y_screen = current_mouse[2] - plot_y

    # Calculate total drag vector from drag start
    delta_x_screen = current_x_screen - start_x_screen
    delta_y_screen = current_y_screen - start_y_screen

    # Only proceed if there's actually some movement.
    # This prevents drift
    if abs(delta_x_screen) < 0.5 && abs(delta_y_screen) < 0.5
        return  # No significant movement, don't update
    end

    # Get the effective bounds at the time drag started
    # We'll calculate this based on what the bounds were when drag began
    drag_start_bounds = if !isnothing(current_state.current_x_min) && !isnothing(current_state.current_x_max) &&
       !isnothing(current_state.current_y_min) && !isnothing(current_state.current_y_max)
        # Use current bounds as the drag reference (existing zoom state)
        Rect2f(current_state.current_x_min, current_state.current_y_min,
            current_state.current_x_max - current_state.current_x_min,
            current_state.current_y_max - current_state.current_y_min)
    else
        # Use the effective bounds (which considers initial bounds and auto-calculated bounds)
        get_effective_bounds(current_state)
    end

    # Extract base bounds from drag reference
    base_min_x = drag_start_bounds.x
    base_max_x = drag_start_bounds.x + drag_start_bounds.width
    base_min_y = drag_start_bounds.y
    base_max_y = drag_start_bounds.y + drag_start_bounds.height

    # Convert screen space drag to data space using the base bounds range
    x_range = base_max_x - base_min_x
    y_range = base_max_y - base_min_y

    # Calculate data space offset (invert drag direction for natural feel)
    delta_x_data = -(delta_x_screen / plot_width) * x_range
    delta_y_data = (delta_y_screen / plot_height) * y_range  # Note: Y is flipped in screen coords

    # Apply drag vector to the base bounds for 1:1 movement
    new_min_x = base_min_x + delta_x_data
    new_max_x = base_max_x + delta_x_data
    new_min_y = base_min_y + delta_y_data
    new_max_y = base_max_y + delta_y_data

    # Create new state with updated pan bounds
    new_state = PlotState(current_state;
        current_x_min=new_min_x,
        current_x_max=new_max_x,
        current_y_min=new_min_y,
        current_y_max=new_max_y,
        auto_scale=false  # Disable auto_scale during drag
    )

    # Update the plot state
    view.on_state_change(new_state)
end

"""
Cull point data to only include points within the specified bounds.
Returns culled x and y data arrays.
"""
function cull_point_data(x_data::Vector{Float32}, y_data::Vector{Float32},
    x_min::Float32, x_max::Float32, y_min::Float32, y_max::Float32)
    if length(x_data) != length(y_data)
        return Float32[], Float32[]
    end

    culled_x = Float32[]
    culled_y = Float32[]

    for i in 1:length(x_data)
        x_val = x_data[i]
        y_val = y_data[i]

        # Include point if it's within bounds
        if x_val >= x_min && x_val <= x_max && y_val >= y_min && y_val <= y_max
            push!(culled_x, x_val)
            push!(culled_y, y_val)
        end
    end

    return culled_x, culled_y
end

"""
Cull line data and clip line segments to viewport bounds using proper interpolation.
This function clips line segments at the exact viewport boundaries to prevent 
lines from extending outside the visible area.
Returns culled x and y data arrays with clipped segments.
"""
function cull_line_data(x_data::Vector{Float32}, y_data::Vector{Float32},
    x_min::Float32, x_max::Float32, y_min::Float32, y_max::Float32)
    if length(x_data) != length(y_data) || length(x_data) < 2
        return Float32[], Float32[]
    end

    culled_x = Float32[]
    culled_y = Float32[]

    # Helper function to check if a point is inside bounds
    function point_in_bounds(x::Float32, y::Float32)::Bool
        return x >= x_min && x <= x_max && y >= y_min && y <= y_max
    end

    # Cohen-Sutherland line clipping algorithm
    # Compute outcode for a point relative to the clipping rectangle
    function compute_outcode(x::Float32, y::Float32)::UInt8
        code = 0x00
        if x < x_min
            code |= 0x01  # LEFT
        elseif x > x_max
            code |= 0x02  # RIGHT
        end
        if y < y_min
            code |= 0x04  # BOTTOM
        elseif y > y_max
            code |= 0x08  # TOP
        end
        return code
    end

    # Clip a line segment to the viewport bounds
    function clip_line_segment(x1::Float32, y1::Float32, x2::Float32, y2::Float32)
        outcode1 = compute_outcode(x1, y1)
        outcode2 = compute_outcode(x2, y2)

        accept = false

        while true
            if (outcode1 | outcode2) == 0  # Both points inside
                accept = true
                break
            elseif (outcode1 & outcode2) != 0  # Both points on same side outside
                break  # Trivially reject
            else
                # At least one point is outside - clip it
                x = 0.0f0
                y = 0.0f0

                # Pick the point that is outside
                outcode_out = outcode1 != 0 ? outcode1 : outcode2

                # Find intersection point using line equation
                # y = y1 + slope * (x - x1), where slope = (y2 - y1) / (x2 - x1)
                if (outcode_out & 0x08) != 0  # TOP
                    x = x1 + (x2 - x1) * (y_max - y1) / (y2 - y1)
                    y = y_max
                elseif (outcode_out & 0x04) != 0  # BOTTOM
                    x = x1 + (x2 - x1) * (y_min - y1) / (y2 - y1)
                    y = y_min
                elseif (outcode_out & 0x02) != 0  # RIGHT
                    y = y1 + (y2 - y1) * (x_max - x1) / (x2 - x1)
                    x = x_max
                elseif (outcode_out & 0x01) != 0  # LEFT
                    y = y1 + (y2 - y1) * (x_min - x1) / (x2 - x1)
                    x = x_min
                end

                # Update the point that was outside and its outcode
                if outcode_out == outcode1
                    x1 = x
                    y1 = y
                    outcode1 = compute_outcode(x1, y1)
                else
                    x2 = x
                    y2 = y
                    outcode2 = compute_outcode(x2, y2)
                end
            end
        end

        if accept
            return true, x1, y1, x2, y2
        else
            return false, 0.0f0, 0.0f0, 0.0f0, 0.0f0
        end
    end

    # Process line segments
    for i in 1:(length(x_data)-1)
        x1, y1 = x_data[i], y_data[i]
        x2, y2 = x_data[i+1], y_data[i+1]

        # Skip if either point is NaN
        if isnan(x1) || isnan(y1) || isnan(x2) || isnan(y2)
            if !isempty(culled_x) && !isnan(culled_x[end])
                # Add NaN to break line continuity
                push!(culled_x, NaN32)
                push!(culled_y, NaN32)
            end
            continue
        end

        # Clip the line segment to viewport bounds
        clipped, cx1, cy1, cx2, cy2 = clip_line_segment(x1, y1, x2, y2)

        if clipped
            # Check if we need to start a new line segment
            need_new_segment = false
            if isempty(culled_x) || isnan(culled_x[end])
                need_new_segment = true
            else
                # Check if this segment connects to the previous one
                last_x, last_y = culled_x[end], culled_y[end]
                if abs(last_x - cx1) > 1e-6 || abs(last_y - cy1) > 1e-6
                    need_new_segment = true
                end
            end

            if need_new_segment
                # Start new segment
                if !isempty(culled_x) && !isnan(culled_x[end])
                    push!(culled_x, NaN32)
                    push!(culled_y, NaN32)
                end
                push!(culled_x, cx1)
                push!(culled_y, cy1)
            end

            # Add the end point
            push!(culled_x, cx2)
            push!(culled_y, cy2)
        else
            # Segment is completely outside - break line continuity
            if !isempty(culled_x) && !isnan(culled_x[end])
                push!(culled_x, NaN32)
                push!(culled_y, NaN32)
            end
        end
    end

    return culled_x, culled_y
end

"""
Draw a colorbar gradient using the existing heatmap drawing system with proper coordinate transform.
"""
function draw_colorbar_gradient(
    element::Union{VerticalColorbar,HorizontalColorbar},
    orientation::Symbol,
    data_x_min::Float32, data_y_min::Float32,
    data_x_max::Float32, data_y_max::Float32,
    data_to_screen::Function,
    projection_matrix::Mat4{Float32},
    effective_bounds::Rect2f
)
    # Create gradient data that maps to the coordinate range
    if orientation == :vertical
        # For vertical colorbar: create thin tall matrix (2 columns, gradient_pixels rows)
        cols, rows = 2, element.gradient_pixels
        # Create gradient from bottom (data_y_min) to top (data_y_max)
        gradient_data = Float32[data_y_min + (j - 1) / (rows - 1) * (data_y_max - data_y_min) for i in 1:cols, j in 1:rows]
    else
        # For horizontal colorbar: create thin wide matrix (gradient_pixels columns, 2 rows)
        cols, rows = element.gradient_pixels, 2
        # Create gradient from left (data_x_min) to right (data_x_max)
        gradient_data = Float32[data_x_min + (i - 1) / (cols - 1) * (data_x_max - data_x_min) for i in 1:cols, j in 1:rows]
    end

    # Create a temporary HeatmapElement with the proper coordinate ranges
    temp_heatmap = HeatmapElement(
        gradient_data;
        x_range=(data_x_min, data_x_max),
        y_range=(data_y_min, data_y_max),
        colormap=element.colormap,
        nan_color=(1.0f0, 0.0f0, 1.0f0, 1.0f0),
        background_color=(0.0f0, 0.0f0, 0.0f0, 1.0f0),
        value_range=element.value_range  # Use the actual value range for color mapping
    )

    # Use the existing heatmap drawing function with the provided data_to_screen transform
    draw_image_plot_clipped(
        temp_heatmap,
        data_to_screen,  # Use the provided coordinate transform
        projection_matrix,
        effective_bounds;
        anti_aliasing_width=1.0f0
    )
end