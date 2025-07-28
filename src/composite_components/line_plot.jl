mutable struct LinePlotStyle
    line_color::Vec4{Float32}
    line_width::Float32
    background_color::Vec4{Float32}
    grid_color::Vec4{Float32}
    axis_color::Vec4{Float32}
    padding_px::Float32
    show_grid::Bool
    show_axes::Bool
end

function LinePlotStyle(;
    line_color=Vec4{Float32}(0.2f0, 0.6f0, 0.8f0, 1.0f0),  # Blue line
    line_width=2.0f0,
    background_color=Vec4{Float32}(1.0f0, 1.0f0, 1.0f0, 1.0f0),  # White background
    grid_color=Vec4{Float32}(0.9f0, 0.9f0, 0.9f0, 1.0f0),  # Light gray grid
    axis_color=Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 1.0f0),  # Black axes
    padding_px=20.0f0,
    show_grid=true,
    show_axes=true
)
    return LinePlotStyle(line_color, line_width, background_color, grid_color, axis_color, padding_px, show_grid, show_axes)
end

struct LinePlotState
    x_data::Vector{Float32}
    y_data::Vector{Float32}
    bounds::Rect2f  # Plot bounds (min_x, min_y, width, height)
    auto_scale::Bool
end

function LinePlotState(
    y_data::Vector{<:Real};
    x_data::Union{Vector{<:Real},Nothing}=nothing,
    bounds::Union{Rect2f,Nothing}=nothing,
    auto_scale::Bool=true
)
    # Convert to Float32
    y_f32 = Float32.(y_data)

    # Generate x_data if not provided
    if x_data === nothing
        x_f32 = Float32.(1:length(y_data))
    else
        x_f32 = Float32.(x_data)
    end

    # Auto-calculate bounds if not provided and auto_scale is true
    if bounds === nothing && auto_scale && !isempty(x_f32) && !isempty(y_f32)
        min_x, max_x = extrema(x_f32)
        min_y, max_y = extrema(y_f32)

        # Add 5% padding
        x_range = max_x - min_x
        y_range = max_y - min_y

        x_padding = x_range * 0.05f0
        y_padding = y_range * 0.05f0

        bounds = Rect2f(
            min_x - x_padding,
            min_y - y_padding,
            x_range + 2 * x_padding,
            y_range + 2 * y_padding
        )
    elseif bounds === nothing
        bounds = Rect2f(0, 0, 1, 1)  # Default bounds
    end

    return LinePlotState(x_f32, y_f32, bounds, auto_scale)
end

struct LinePlotView <: AbstractView
    state::LinePlotState
    style::LinePlotStyle
    on_state_change::Function
end

function LinePlot(
    y_data::Vector{<:Real};
    x_data::Union{Vector{<:Real},Nothing}=nothing,
    state::Union{LinePlotState,Nothing}=nothing,
    style::LinePlotStyle=LinePlotStyle(),
    on_state_change::Function=(new_state) -> nothing
)::LinePlotView
    if state === nothing
        state = LinePlotState(y_data; x_data=x_data)
    end
    return LinePlotView(state, style, on_state_change)
end

function measure(view::LinePlotView)::Tuple{Float32,Float32}
    return (Inf32, Inf32)  # Take all available space
end

function apply_layout(view::LinePlotView, x::Float32, y::Float32, width::Float32, height::Float32)
    return (x, y, width, height)
end

function interpret_view(view::LinePlotView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    state = view.state
    style = view.style

    # Draw background
    bg_vertices = generate_rectangle_vertices(x, y, width, height)
    draw_filled_rectangle(bg_vertices, style.background_color, projection_matrix)

    # Calculate plot area (subtract padding)
    plot_x = x + style.padding_px
    plot_y = y + style.padding_px
    plot_width = width - 2 * style.padding_px
    plot_height = height - 2 * style.padding_px

    if plot_width <= 0 || plot_height <= 0 || isempty(state.x_data) || isempty(state.y_data)
        return  # Not enough space or no data to draw
    end

    # Transform data coordinates to screen coordinates
    function data_to_screen(data_x::Float32, data_y::Float32)::Tuple{Float32,Float32}
        # Map from data bounds to plot area
        bounds = state.bounds
        norm_x = (data_x - bounds.x) / bounds.width
        norm_y = (data_y - bounds.y) / bounds.height

        screen_x = plot_x + norm_x * plot_width
        screen_y = plot_y + (1.0f0 - norm_y) * plot_height  # Flip Y axis

        return (screen_x, screen_y)
    end

    # Draw grid if enabled
    if style.show_grid
        # TODO: Implement grid drawing
        # This would require additional drawing functions for lines
    end

    # Draw axes if enabled
    if style.show_axes
        # TODO: Implement axis drawing
    end

    # Draw the line plot
    if length(state.x_data) >= 2 && length(state.y_data) >= 2
        draw_line_plot(
            state.x_data,
            state.y_data,
            data_to_screen,
            style.line_color,
            style.line_width,
            projection_matrix
        )
    end
end

function detect_click(view::LinePlotView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32)
    # For now, plots don't handle clicks
    # Could add zoom/pan functionality later
    return
end

