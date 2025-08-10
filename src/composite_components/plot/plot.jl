abstract type AbstractPlotElement end

using ModernGL  # For scissor testing to clip plot traces

include("rec2f.jl")
include("line_style.jl")
include("plot_style.jl")
include("shaders.jl")
include("line_draw.jl")
include("marker_draw.jl")
include("plot_state.jl")

# Line plot element
struct LinePlotElement <: AbstractPlotElement
    x_data::Vector{Float32}
    y_data::Vector{Float32}
    color::Vec4{Float32}
    width::Float32
    line_style::LineStyle
    label::String
end

# Scatter plot element
struct ScatterPlotElement <: AbstractPlotElement
    x_data::Vector{Float32}
    y_data::Vector{Float32}
    fill_color::Vec4{Float32}
    border_color::Vec4{Float32}
    marker_size::Float32
    border_width::Float32
    marker_type::MarkerType
    label::String
end

# Stem plot element
struct StemPlotElement <: AbstractPlotElement
    x_data::Vector{Float32}
    y_data::Vector{Float32}
    line_color::Vec4{Float32}
    fill_color::Vec4{Float32}
    border_color::Vec4{Float32}
    line_width::Float32
    marker_size::Float32
    border_width::Float32
    marker_type::MarkerType
    baseline::Float32  # Y value for stem baseline
    label::String
end

# Image/Matrix plot element
struct ImagePlotElement <: AbstractPlotElement
    data::Matrix{Float32}
    x_range::Tuple{Float32,Float32}  # (min_x, max_x)
    y_range::Tuple{Float32,Float32}  # (min_y, max_y)
    colormap::Symbol  # :viridis, :plasma, :grayscale, etc.
    label::String
end

# Convenience constructors for plot elements
function LinePlotElement(
    y_data::Vector{<:Real};
    x_data::Union{Vector{<:Real},Nothing}=nothing,
    color::Vec4{Float32}=Vec4{Float32}(0.2f0, 0.6f0, 0.8f0, 1.0f0),
    width::Float32=2.0f0,
    line_style::LineStyle=SOLID,
    label::String=""
)
    y_f32 = Float32.(y_data)
    x_f32 = x_data === nothing ? Float32.(1:length(y_data)) : Float32.(x_data)
    return LinePlotElement(x_f32, y_f32, color, width, line_style, label)
end

function ScatterPlotElement(
    y_data::Vector{<:Real};
    x_data::Union{Vector{<:Real},Nothing}=nothing,
    fill_color::Vec4{Float32}=Vec4{Float32}(0.2f0, 0.2f0, 1.0f0, 1.0f0),
    border_color::Vec4{Float32}=Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 1.0f0),
    marker_size::Float32=5.0f0,
    border_width::Float32=1.50f0,
    marker_type::MarkerType=CIRCLE,
    label::String=""
)
    y_f32 = Float32.(y_data)
    x_f32 = x_data === nothing ? Float32.(1:length(y_data)) : Float32.(x_data)
    return ScatterPlotElement(x_f32, y_f32, fill_color, border_color, marker_size, border_width, marker_type, label)
end

function StemPlotElement(
    y_data::Vector{<:Real};
    x_data::Union{Vector{<:Real},Nothing}=nothing,
    line_color::Vec4{Float32}=Vec4{Float32}(0.2f0, 0.2f0, 1.0f0, 1.0f0),
    fill_color::Vec4{Float32}=Vec4{Float32}(0.2f0, 0.2f0, 1.0f0, 1.0f0),
    border_color::Vec4{Float32}=Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 0.0f0),
    line_width::Float32=2.0f0,
    marker_size::Float32=5.0f0,
    border_width::Float32=0.0f0,
    marker_type::MarkerType=CIRCLE,
    baseline::Float32=0.0f0,
    label::String=""
)
    y_f32 = Float32.(y_data)
    x_f32 = x_data === nothing ? Float32.(1:length(y_data)) : Float32.(x_data)
    return StemPlotElement(x_f32, y_f32, line_color, fill_color, border_color, line_width, marker_size, border_width, marker_type, baseline, label)
end

function ImagePlotElement(
    data::Matrix{<:Real};
    x_range::Tuple{Real,Real}=(1, size(data, 2)),
    y_range::Tuple{Real,Real}=(1, size(data, 1)),
    colormap::Symbol=:viridis,
    label::String=""
)
    data_f32 = Float32.(data)
    x_range_f32 = (Float32(x_range[1]), Float32(x_range[2]))
    y_range_f32 = (Float32(y_range[1]), Float32(y_range[2]))
    return ImagePlotElement(data_f32, x_range_f32, y_range_f32, colormap, label)
end

# Helper function to extract data bounds from any plot element
function get_element_bounds(element::AbstractPlotElement)::Tuple{Float32,Float32,Float32,Float32}
    if element isa LinePlotElement || element isa ScatterPlotElement || element isa StemPlotElement
        if !isempty(element.x_data) && !isempty(element.y_data)
            min_x, max_x = extrema(element.x_data)
            min_y, max_y = extrema(element.y_data)
            return (min_x, max_x, min_y, max_y)
        end
    elseif element isa ImagePlotElement
        min_x, max_x = element.x_range
        min_y, max_y = element.y_range
        return (min_x, max_x, min_y, max_y)
    end
    return (0.0f0, 1.0f0, 0.0f0, 1.0f0)  # Default bounds
end

struct PlotView <: AbstractView
    elements::Vector{AbstractPlotElement}
    state::PlotState
    style::PlotStyle
    on_state_change::Function
end

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
        state = PlotState(calculated_bounds, state.auto_scale, state.initial_x_min, state.initial_x_max, state.initial_y_min, state.initial_y_max, state.current_x_min, state.current_x_max, state.current_y_min, state.current_y_max)
    end
    return PlotView(elements, state, style, on_state_change)
end
# Convenience constructors for specific plot types
function LinePlot(
    elements::Vector{LinePlotElement};
    style::PlotStyle=PlotStyle(),
    on_state_change::Function=(new_state) -> nothing
)::PlotView
    return Plot(Vector{AbstractPlotElement}(elements), PlotState(), style, on_state_change)
end

function measure(view::PlotView)::Tuple{Float32,Float32}
    return (Inf32, Inf32)  # Take all available space
end

function apply_layout(view::PlotView, x::Float32, y::Float32, width::Float32, height::Float32)
    return (x, y, width, height)
end

function interpret_view(view::PlotView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    state = view.state
    style = view.style
    elements = view.elements

    # Draw background
    bg_vertices = generate_rectangle_vertices(x, y, width, height)
    draw_rectangle(bg_vertices, style.background_color, projection_matrix)

    # Calculate plot area (subtract padding)
    plot_x = x + style.padding_px
    plot_y = y + style.padding_px
    plot_width = width - 2 * style.padding_px
    plot_height = height - 2 * style.padding_px

    if plot_width <= 0 || plot_height <= 0 || isempty(elements)
        return  # Not enough space or no data to draw
    end

    # Transform data coordinates to screen coordinates
    function data_to_screen(data_x::Float32, data_y::Float32)::Tuple{Float32,Float32}
        # Map from effective bounds (considering zoom state) to plot area
        effective_bounds = get_effective_bounds(state, style)
        norm_x = (data_x - effective_bounds.x) / effective_bounds.width
        norm_y = (data_y - effective_bounds.y) / effective_bounds.height

        screen_x = plot_x + norm_x * plot_width
        screen_y = plot_y + (1.0f0 - norm_y) * plot_height  # Flip Y axis

        return (screen_x, screen_y)
    end

    # Draw grid if enabled
    if style.show_grid
        effective_bounds = get_effective_bounds(state, style)
        x_ticks = generate_tick_positions(effective_bounds.x, effective_bounds.x + effective_bounds.width)
        y_ticks = generate_tick_positions(effective_bounds.y, effective_bounds.y + effective_bounds.height)
        screen_bounds = Rect2f(x, y, width, height)

        draw_grid_with_labels(
            effective_bounds,
            x_ticks,
            y_ticks,
            data_to_screen,
            screen_bounds,
            style.grid_color,
            1.0f0,  # Grid line width
            DOT,  # DOT line style for grid
            projection_matrix;
            axis_color=style.axis_color,
            anti_aliasing_width=style.anti_aliasing_width
        )
    end

    # Draw axes if enabled
    if style.show_axes
        effective_bounds = get_effective_bounds(state, style)
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
            anti_aliasing_width=style.anti_aliasing_width
        )
    end

    # Draw all plot elements with clipping enabled
    # Enable scissor testing to clip drawing to plot area
    ModernGL.glEnable(ModernGL.GL_SCISSOR_TEST)

    # Get current viewport to properly convert coordinates
    viewport = Vector{Int32}(undef, 4)
    ModernGL.glGetIntegerv(ModernGL.GL_VIEWPORT, viewport)
    viewport_height = viewport[4]

    # Set scissor rectangle to plot area
    # Convert from top-left coordinates (Fugl) to bottom-left coordinates (OpenGL)
    scissor_x = Int32(round(plot_x))
    scissor_y = Int32(viewport_height - round(plot_y + plot_height))
    scissor_width = Int32(round(plot_width))
    scissor_height = Int32(round(plot_height))
    ModernGL.glScissor(scissor_x, scissor_y, scissor_width, scissor_height)

    # Draw plot elements (will be clipped to scissor rectangle)
    for element in elements
        draw_plot_element(element, data_to_screen, projection_matrix, style, state.bounds)
    end

    # Disable scissor testing
    ModernGL.glDisable(ModernGL.GL_SCISSOR_TEST)
end

# Drawing functions for different plot element types
function draw_plot_element(element::LinePlotElement, data_to_screen::Function, projection_matrix::Mat4{Float32}, style::PlotStyle, bounds::Rect2f)
    if length(element.x_data) >= 2 && length(element.y_data) >= 2
        draw_line_plot(
            element.x_data,
            element.y_data,
            data_to_screen,
            element.color,
            element.width,
            element.line_style,
            projection_matrix;
            anti_aliasing_width=style.anti_aliasing_width
        )
    end
end

function draw_plot_element(element::ScatterPlotElement, data_to_screen::Function, projection_matrix::Mat4{Float32}, style::PlotStyle, bounds::Rect2f)
    if length(element.x_data) >= 1 && length(element.y_data) >= 1
        draw_scatter_plot(
            element.x_data,
            element.y_data,
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

function draw_plot_element(element::StemPlotElement, data_to_screen::Function, projection_matrix::Mat4{Float32}, style::PlotStyle, bounds::Rect2f)
    if length(element.x_data) >= 1 && length(element.y_data) >= 1
        # Calculate the visible Y bounds
        min_y_visible = bounds.y
        max_y_visible = bounds.y + bounds.height

        # Draw vertical lines from baseline (clipped to visible area) to each data point
        for i in 1:length(element.x_data)
            x_val = element.x_data[i]
            y_val = element.y_data[i]

            # Clip the baseline to the visible plot area
            # If baseline is below the visible area, start from the bottom edge
            # If baseline is above the visible area, start from the top edge
            clipped_baseline = clamp(element.baseline, min_y_visible, max_y_visible)

            # Only draw the stem if the data point and clipped baseline are different
            if abs(clipped_baseline - y_val) > 1e-6  # Avoid drawing zero-length lines
                stem_x_data = [x_val, x_val]
                stem_y_data = [clipped_baseline, y_val]

                draw_line_plot(
                    stem_x_data,
                    stem_y_data,
                    data_to_screen,
                    element.line_color,
                    element.line_width,
                    SOLID,  # SOLID line style
                    projection_matrix;
                    anti_aliasing_width=style.anti_aliasing_width
                )
            end
        end

        # Draw markers at data points
        draw_scatter_plot(
            element.x_data,
            element.y_data,
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

function draw_plot_element(element::ImagePlotElement, data_to_screen::Function, projection_matrix::Mat4{Float32}, style::PlotStyle, bounds::Rect2f)
    # TODO: Implement image/matrix plot drawing
    # This will require texture mapping and colormap support
    println("ImagePlot drawing not yet implemented")
end

function detect_click(view::PlotView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32)
    # For now, plots don't handle clicks
    # Could add zoom/pan functionality later
    return
end