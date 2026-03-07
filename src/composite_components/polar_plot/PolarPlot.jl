"""
Polar plot component for visualizing data in polar coordinates.
"""

include("polar_transform.jl")
include("polar_style.jl")
include("polar_state.jl")
include("polar_elements.jl")
include("polar_axes.jl")

struct PolarPlotView <: AbstractView
    elements::Vector{AbstractPolarElement}
    state::PolarState
    style::PolarStyle
    on_state_change::Function
end

"""
Create a polar plot component.

# Arguments
- `elements`: Vector of polar plot elements (lines, scatter, etc.)
- `style`: PolarStyle for appearance customization
- `state`: PolarState for coordinate system configuration
- `on_state_change`: Callback function when state changes

# Example
```julia
theta = range(0, 2π, length=100)
r = 1 .+ 0.5 .* cos.(5 .* theta)

polar_plot = PolarPlot(
    [PolarLine(r, theta, color=Vec4f(0.0, 0.5, 1.0, 1.0))],
    PolarStyle(),
    PolarState(theta_start=Float32(π/2))  # 0° points up
)
```
"""
function PolarPlot(
    elements::Vector{<:AbstractPolarElement},
    style::PolarStyle=PolarStyle(),
    state::PolarState=PolarState(),
    on_state_change::Function=(new_state) -> nothing
)::PolarPlotView
    # Auto-scale r_max if enabled and elements exist
    if state.auto_scale_r && !isempty(elements)
        max_r = 0.0f0
        for element in elements
            if isa(element, PolarLineElement)
                max_r = max(max_r, maximum(element.r_data))
            elseif isa(element, PolarScatterElement)
                max_r = max(max_r, maximum(element.r_data))
            elseif isa(element, PolarStemElement)
                max_r = max(max_r, maximum(element.r_data))
            end
        end

        # Add 10% padding to max radius
        max_r *= 1.1f0
        state = PolarState(state; r_max=max_r, auto_scale_r=false)
    end

    return PolarPlotView(elements, state, style, on_state_change)
end

function measure(view::PolarPlotView)::Tuple{Float32,Float32}
    # Prefer square aspect ratio, take all available space
    return (Inf32, Inf32)
end

function apply_layout(view::PolarPlotView, x::Float32, y::Float32, width::Float32, height::Float32)
    return (x, y, width, height)
end

function interpret_view(
    view::PolarPlotView,
    x::Float32,
    y::Float32,
    width::Float32,
    height::Float32,
    projection_matrix::Mat4{Float32},
    mouse_x::Float32,
    mouse_y::Float32
)
    # Get plot render cache
    cache = get_render_cache(view.state.cache_id)

    cache_width = Int32(round(width))
    cache_height = Int32(round(height))

    if cache_width <= 0 || cache_height <= 0
        return
    end

    # Generate content hash
    content_hash = hash((view.elements, view.state, view.style))
    bounds = (x, y, width, height)

    # Check if we need to redraw
    needs_redraw = should_invalidate_cache(cache, content_hash, bounds)

    if needs_redraw || !cache.is_valid
        if cache.framebuffer === nothing || cache.cache_width != cache_width || cache.cache_height != cache_height
            (framebuffer, color_texture, depth_texture) = create_render_framebuffer(cache_width, cache_height; with_depth=false)
            update_cache!(cache, framebuffer, color_texture, depth_texture, content_hash, bounds)
        else
            update_cache!(cache, cache.framebuffer, cache.color_texture, cache.depth_texture, content_hash, bounds)
        end

        # Render to framebuffer
        render_polar_plot_to_framebuffer(view, cache, width, height, projection_matrix)
    end

    if cache.is_valid && cache.color_texture !== nothing && cache_width > 0 && cache_height > 0
        draw_cached_texture(cache.color_texture, x, y, width, height, projection_matrix)
    end
end

function render_polar_plot_to_framebuffer(
    view::PolarPlotView,
    cache::RenderCache,
    width::Float32,
    height::Float32,
    projection_matrix::Mat4{Float32}
)
    push_framebuffer!(cache.framebuffer)
    push_viewport!(Int32(0), Int32(0), cache.cache_width, cache.cache_height)

    try
        # Clear framebuffer
        bg = view.style.background_color
        ModernGL.glClearColor(bg[1], bg[2], bg[3], bg[4])
        ModernGL.glClear(ModernGL.GL_COLOR_BUFFER_BIT | ModernGL.GL_DEPTH_BUFFER_BIT)

        # Create framebuffer-specific projection matrix
        fb_projection = get_orthographic_matrix(0.0f0, width, height, 0.0f0, -1.0f0, 1.0f0)

        # Render content
        render_polar_content(view, 0.0f0, 0.0f0, width, height, fb_projection)
    finally
        pop_viewport!()
        pop_framebuffer!()
    end
end

function render_polar_content(
    view::PolarPlotView,
    x::Float32,
    y::Float32,
    width::Float32,
    height::Float32,
    projection_matrix::Mat4{Float32}
)
    state = view.state
    style = view.style
    elements = view.elements

    # Calculate plot area with padding
    plot_area_x = x + style.padding
    plot_area_y = y + style.padding
    plot_area_width = width - 2.0f0 * style.padding
    plot_area_height = height - 2.0f0 * style.padding

    if plot_area_width <= 0 || plot_area_height <= 0
        return
    end

    # Calculate center and radius for polar plot
    # Use the smaller dimension to ensure circle fits
    max_plot_radius = min(plot_area_width, plot_area_height) / 2.0f0
    center_x = plot_area_x + plot_area_width / 2.0f0
    center_y = plot_area_y + plot_area_height / 2.0f0

    # Create transform from polar data coordinates to screen coordinates
    function polar_data_to_screen(r::Float32, theta::Float32)::Tuple{Float32,Float32}
        # Check if theta is within visible range
        theta_min, theta_max = state.theta_range
        if theta < theta_min || theta > theta_max
            return (NaN32, NaN32)  # Outside visible range
        end

        # Normalize radius to screen radius
        r_normalized = (r - state.r_min) / (state.r_max - state.r_min)
        screen_radius = r_normalized * max_plot_radius

        # Convert to Cartesian screen coordinates
        return polar_to_cartesian(
            screen_radius,
            theta,
            state.theta_start,
            state.theta_direction,
            center_x,
            center_y
        )
    end

    # Draw radial grid circles
    if style.show_radial_grid
        radii = Float32[max_plot_radius * i / state.num_radial_circles for i in 1:state.num_radial_circles]
        draw_radial_circles(
            center_x,
            center_y,
            radii,
            style.radial_grid_color,
            style.radial_grid_width,
            projection_matrix;
            anti_aliasing_width=style.anti_aliasing_width
        )
    end

    # Draw angular ticks on radial circles
    if style.show_angular_ticks
        radii = Float32[max_plot_radius * i / state.num_radial_circles for i in 1:state.num_radial_circles]
        draw_angular_ticks(
            center_x,
            center_y,
            radii,
            state.theta_start,
            state.theta_direction,
            style.angular_tick_size,
            style.angular_tick_color,
            style.angular_tick_width,
            projection_matrix;
            anti_aliasing_width=style.anti_aliasing_width
        )
    end

    # Draw angular grid lines
    if style.show_angular_grid
        theta_min, theta_max = state.theta_range
        theta_span = theta_max - theta_min
        angles = Float32[theta_min + theta_span * i / state.num_angular_lines for i in 0:(state.num_angular_lines-1)]

        draw_angular_lines(
            center_x,
            center_y,
            max_plot_radius,
            angles,
            state.theta_start,
            state.theta_direction,
            style.angular_grid_color,
            style.angular_grid_width,
            projection_matrix;
            anti_aliasing_width=style.anti_aliasing_width
        )
    end

    # Draw radial ticks on outer circle
    if style.show_radial_ticks
        theta_min, theta_max = state.theta_range
        theta_span = theta_max - theta_min
        angles = Float32[theta_min + theta_span * i / state.num_angular_lines for i in 0:(state.num_angular_lines-1)]

        draw_radial_ticks(
            center_x,
            center_y,
            max_plot_radius,
            angles,
            state.theta_start,
            state.theta_direction,
            style.radial_tick_size,
            style.radial_tick_color,
            style.radial_tick_width,
            projection_matrix;
            anti_aliasing_width=style.anti_aliasing_width
        )
    end

    # Draw outer circle
    if style.show_outer_circle
        draw_radial_circles(
            center_x,
            center_y,
            Float32[max_plot_radius],
            style.outer_circle_color,
            style.outer_circle_width,
            projection_matrix;
            anti_aliasing_width=style.anti_aliasing_width
        )
    end

    # Draw plot elements
    for element in elements
        draw_polar_element(element, polar_data_to_screen, projection_matrix, style)
    end

    # Draw labels
    if style.show_radial_labels
        radii = Float32[max_plot_radius * i / state.num_radial_circles for i in 1:state.num_radial_circles]
        draw_radial_labels(
            center_x,
            center_y,
            radii,
            state.r_min,
            state.r_max,
            state.theta_start,
            style.label_color,
            style.label_size_px,
            projection_matrix
        )
    end

    if style.show_angular_labels
        theta_min, theta_max = state.theta_range
        theta_span = theta_max - theta_min
        angles = Float32[theta_min + theta_span * i / state.num_angular_lines for i in 0:(state.num_angular_lines-1)]

        draw_angular_labels(
            center_x,
            center_y,
            max_plot_radius,
            angles,
            state.theta_start,
            state.theta_direction,
            state.angular_label_format,
            style.label_color,
            style.label_size_px,
            projection_matrix
        )
    end
end

"""
Draw a polar element by converting polar coordinates to Cartesian screen coordinates.
"""
function draw_polar_element(
    element::PolarLineElement,
    polar_to_screen::Function,
    projection_matrix::Mat4{Float32},
    style::PolarStyle
)
    # Convert polar data to Cartesian screen coordinates
    x_screen = Float32[]
    y_screen = Float32[]

    for i in 1:length(element.r_data)
        x, y = polar_to_screen(element.r_data[i], element.theta_data[i])
        push!(x_screen, x)
        push!(y_screen, y)
    end

    # Use identity transform since we're already in screen coordinates
    identity_transform(x, y) = (x, y)

    # Draw line
    if length(x_screen) >= 2
        draw_line_plot(
            x_screen,
            y_screen,
            identity_transform,
            element.color,
            element.width,
            element.line_style,
            projection_matrix;
            anti_aliasing_width=style.anti_aliasing_width
        )
    end
end

function draw_polar_element(
    element::PolarScatterElement,
    polar_to_screen::Function,
    projection_matrix::Mat4{Float32},
    style::PolarStyle
)
    # Convert polar data to Cartesian screen coordinates
    x_screen = Float32[]
    y_screen = Float32[]

    for i in 1:length(element.r_data)
        x, y = polar_to_screen(element.r_data[i], element.theta_data[i])
        push!(x_screen, x)
        push!(y_screen, y)
    end

    # Use identity transform since we're already in screen coordinates
    identity_transform(x, y) = (x, y)

    # Draw markers
    if length(x_screen) >= 1
        draw_scatter_plot(
            x_screen,
            y_screen,
            identity_transform,
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

function draw_polar_element(
    element::PolarStemElement,
    polar_to_screen::Function,
    projection_matrix::Mat4{Float32},
    style::PolarStyle
)
    # Convert polar data to Cartesian screen coordinates
    x_screen = Float32[]
    y_screen = Float32[]

    for i in 1:length(element.r_data)
        x, y = polar_to_screen(element.r_data[i], element.theta_data[i])
        push!(x_screen, x)
        push!(y_screen, y)
    end

    # Use identity transform since we're already in screen coordinates
    identity_transform(x, y) = (x, y)

    # Draw stem lines from r=0 (or r_min if r=0 is not visible) to each point
    for i in 1:length(x_screen)
        # Calculate stem origin for this angle
        # Stems should start at r=0 in data space, but if that's outside visible range,
        # start at the edge of the visible range (r_min)
        stem_origin_x, stem_origin_y = polar_to_screen(0.0f0, element.theta_data[i])

        stem_x = Float32[stem_origin_x, x_screen[i]]
        stem_y = Float32[stem_origin_y, y_screen[i]]

        draw_line_plot(
            stem_x,
            stem_y,
            identity_transform,
            element.stem_color,
            element.stem_width,
            SOLID,
            projection_matrix;
            anti_aliasing_width=style.anti_aliasing_width
        )
    end

    # Draw markers at each data point
    if length(x_screen) >= 1
        draw_scatter_plot(
            x_screen,
            y_screen,
            identity_transform,
            element.marker_fill_color,
            element.marker_border_color,
            element.marker_size,
            element.marker_border_width,
            element.marker_type,
            projection_matrix;
            anti_aliasing_width=style.anti_aliasing_width
        )
    end
end

function detect_click(
    view::PolarPlotView,
    mouse_state::InputState,
    x::Float32,
    y::Float32,
    width::Float32,
    height::Float32,
    parent_z::Int32
)::Union{ClickResult,Nothing}
    z = Int32(parent_z + 1)

    # Check for scroll wheel zoom with Ctrl/Cmd modifier
    if (mouse_state.scroll_y != 0.0) && is_command_key(mouse_state.modifier_keys)
        # Get mouse position relative to plot area
        mouse_x = Float32(mouse_state.x) - x
        mouse_y = Float32(mouse_state.y) - y

        # Check if mouse is within plot bounds
        if mouse_x >= 0 && mouse_x <= width && mouse_y >= 0 && mouse_y <= height
            zoom_action() = handle_scroll_zoom(view, mouse_x, mouse_y, width, height, Float32(mouse_state.scroll_y))
            return ClickResult(z, () -> zoom_action())
        end
    end

    return nothing
end

function handle_scroll_zoom(
    view::PolarPlotView,
    mouse_x::Float32,
    mouse_y::Float32,
    plot_width::Float32,
    plot_height::Float32,
    scroll_y::Float32
)
    # Determine zoom factor based on scroll direction
    zoom_factor = scroll_y > 0 ? 0.9f0 : 1.1f0  # Scroll up = zoom in, scroll down = zoom out

    current_state = view.state

    # Calculate new radial range by zooming
    r_range = current_state.r_max - current_state.r_min
    new_r_range = r_range * zoom_factor

    # Keep the center of the zoom at the current midpoint
    r_center = (current_state.r_max + current_state.r_min) / 2.0f0
    new_r_min = max(0.0f0, r_center - new_r_range / 2.0f0)
    new_r_max = r_center + new_r_range / 2.0f0

    # Create new state with updated radial bounds
    new_state = PolarState(current_state;
        r_min=new_r_min,
        r_max=new_r_max,
        auto_scale_r=false  # Disable auto_scale when user zooms
    )

    # Notify callback for state management
    view.on_state_change(new_state)
end
