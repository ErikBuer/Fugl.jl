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
    padding_px=10.0f0,
    show_grid=true,
    show_axes=true
)
    return LinePlotStyle(line_color, line_width, background_color, grid_color, axis_color, padding_px, show_grid, show_axes)
end

# Line style enumeration
@enum LineStyle begin
    SOLID = 0
    DASH = 1
    DOT = 2
    DASHDOT = 3
end

struct LinePlotTrace
    x_data::Vector{Float32}
    y_data::Vector{Float32}
    color::Vec4{Float32}
    width::Float32
    line_style::LineStyle
    label::String
end

function LinePlotTrace(
    y_data::Vector{<:Real};
    x_data::Union{Vector{<:Real},Nothing}=nothing,
    color::Vec4{Float32}=Vec4{Float32}(0.2f0, 0.6f0, 0.8f0, 1.0f0),
    width::Float32=2.0f0,
    line_style::LineStyle=SOLID,
    label::String=""
)
    # Convert to Float32
    y_f32 = Float32.(y_data)

    # Generate x_data if not provided
    if x_data === nothing
        x_f32 = Float32.(1:length(y_data))
    else
        x_f32 = Float32.(x_data)
    end

    return LinePlotTrace(x_f32, y_f32, color, width, line_style, label)
end

struct LinePlotState
    traces::Vector{LinePlotTrace}
    bounds::Rect2f  # Plot bounds (min_x, min_y, width, height)
    auto_scale::Bool
end

function LinePlotState(
    traces::Vector{LinePlotTrace};
    bounds::Union{Rect2f,Nothing}=nothing,
    auto_scale::Bool=true
)
    # Auto-calculate bounds if not provided and auto_scale is true
    if bounds === nothing && auto_scale && !isempty(traces)
        # Find overall bounds across all traces
        all_x = Float32[]
        all_y = Float32[]

        for trace in traces
            if !isempty(trace.x_data) && !isempty(trace.y_data)
                append!(all_x, trace.x_data)
                append!(all_y, trace.y_data)
            end
        end

        if !isempty(all_x) && !isempty(all_y)
            min_x, max_x = extrema(all_x)
            min_y, max_y = extrema(all_y)

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
        else
            bounds = Rect2f(0, 0, 1, 1)  # Default bounds
        end
    elseif bounds === nothing
        bounds = Rect2f(0, 0, 1, 1)  # Default bounds
    end

    return LinePlotState(traces, bounds, auto_scale)
end

# Convenience constructor for single trace (backward compatibility)
function LinePlotState(
    y_data::Vector{<:Real};
    x_data::Union{Vector{<:Real},Nothing}=nothing,
    bounds::Union{Rect2f,Nothing}=nothing,
    auto_scale::Bool=true
)
    trace = LinePlotTrace(y_data; x_data=x_data)
    return LinePlotState([trace]; bounds=bounds, auto_scale=auto_scale)
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

# Multi-trace constructor
function LinePlot(
    traces::Vector{LinePlotTrace};
    state::Union{LinePlotState,Nothing}=nothing,
    style::LinePlotStyle=LinePlotStyle(),
    on_state_change::Function=(new_state) -> nothing
)::LinePlotView
    if state === nothing
        state = LinePlotState(traces)
    end
    return LinePlotView(state, style, on_state_change)
end

# Convenience constructors for common multi-trace scenarios
function LinePlot(
    traces_data::Vector{Tuple{Vector{<:Real},Vec4{Float32}}};  # (y_data, color) pairs
    x_data::Union{Vector{<:Real},Nothing}=nothing,
    style::LinePlotStyle=LinePlotStyle(),
    on_state_change::Function=(new_state) -> nothing
)::LinePlotView
    traces = [LinePlotTrace(y_data; x_data=x_data, color=color) for (y_data, color) in traces_data]
    return LinePlot(traces; style=style, on_state_change=on_state_change)
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
    draw_rectangle(bg_vertices, style.background_color, projection_matrix)

    # Calculate plot area (subtract padding)
    plot_x = x + style.padding_px
    plot_y = y + style.padding_px
    plot_width = width - 2 * style.padding_px
    plot_height = height - 2 * style.padding_px

    if plot_width <= 0 || plot_height <= 0 || isempty(state.traces)
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
        # Generate reasonable tick positions
        x_ticks = generate_tick_positions(state.bounds.x, state.bounds.x + state.bounds.width)
        y_ticks = generate_tick_positions(state.bounds.y, state.bounds.y + state.bounds.height)

        draw_grid(
            state.bounds,
            x_ticks,
            y_ticks,
            data_to_screen,
            style.grid_color,
            1.0f0,  # Grid line width
            2.0f0,  # DOT line style for grid
            projection_matrix
        )
    end

    # Draw axes if enabled
    if style.show_axes
        draw_axes(
            state.bounds,
            data_to_screen,
            style.axis_color,
            2.0f0,  # Axis line width
            projection_matrix
        )
    end

    # Draw all traces
    for trace in state.traces
        if length(trace.x_data) >= 2 && length(trace.y_data) >= 2
            draw_line_plot(
                trace.x_data,
                trace.y_data,
                data_to_screen,
                trace.color,
                trace.width,
                Float32(Int(trace.line_style)),  # Convert enum to float
                projection_matrix
            )
        end
    end
end

function detect_click(view::LinePlotView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32)
    # For now, plots don't handle clicks
    # Could add zoom/pan functionality later
    return
end

