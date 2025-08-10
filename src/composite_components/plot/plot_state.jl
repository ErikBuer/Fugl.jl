struct PlotState
    elements::Vector{AbstractPlotElement}
    bounds::Rect2f  # Plot bounds (min_x, min_y, width, height)
    auto_scale::Bool
    # Current zoom/view bounds (for user-controlled zooming)
    current_x_min::Union{Float32,Nothing}
    current_x_max::Union{Float32,Nothing}
    current_y_min::Union{Float32,Nothing}
    current_y_max::Union{Float32,Nothing}
end

"""
Convenience constructor for PlotState with auto-calculated bounds
"""
function PlotState(
    elements::Vector{AbstractPlotElement};
    bounds::Union{Rect2f,Nothing}=nothing,
    auto_scale::Bool=true
)
    # Auto-calculate bounds if not provided and auto_scale is true
    if bounds === nothing && auto_scale && !isempty(elements)
        # Find overall bounds across all elements
        all_x = Float32[]
        all_y = Float32[]

        for element in elements
            min_x, max_x, min_y, max_y = get_element_bounds(element)
            push!(all_x, min_x, max_x)
            push!(all_y, min_y, max_y)
        end

        if !isempty(all_x) && !isempty(all_y)
            min_x, max_x = extrema(all_x)
            min_y, max_y = extrema(all_y)

            # Calculate ranges
            x_range = max_x - min_x
            y_range = max_y - min_y

            # Handle constant data by providing minimum range
            min_range = 1.0f0
            if x_range < min_range
                x_range = min_range
                x_center = (max_x + min_x) / 2
                min_x = x_center - x_range / 2
                max_x = x_center + x_range / 2
            end
            if y_range < min_range
                # For constant y values, scale from 0 to the constant value
                constant_value = min_y  # min_y == max_y for constant data
                if constant_value >= 0
                    # Positive constant: scale from 0 to constant + 5%
                    min_y = 0.0f0
                    max_y = constant_value * 1.05f0
                else
                    # Negative constant: scale from constant - 5% to 0
                    min_y = constant_value * 1.05f0  # This makes it more negative
                    max_y = 0.0f0
                end
                y_range = max_y - min_y
            end

            # No padding - traces extend to axis edges
            bounds = Rect2f(
                min_x,
                min_y,
                x_range,
                y_range
            )
        else
            bounds = Rect2f(0, 0, 1, 1)  # Default bounds
        end
    elseif bounds === nothing
        bounds = Rect2f(0, 0, 1, 1)  # Default bounds
    end

    return PlotState(elements, bounds, auto_scale, nothing, nothing, nothing, nothing)
end

"""
Convenience constructors for backward compatibility and single elements
"""
function PlotState(
    y_data::Vector{<:Real};
    x_data::Union{Vector{<:Real},Nothing}=nothing,
    bounds::Union{Rect2f,Nothing}=nothing,
    auto_scale::Bool=true,
    plot_type::PlotType=LINE_PLOT
)
    element = if plot_type == LINE_PLOT
        LinePlotElement(y_data; x_data=x_data)
    elseif plot_type == SCATTER_PLOT
        ScatterPlotElement(y_data; x_data=x_data)
    elseif plot_type == STEM_PLOT
        StemPlotElement(y_data; x_data=x_data)
    else
        LinePlotElement(y_data; x_data=x_data)  # Default to line plot
    end

    elements = [element]

    # Use direct constructor to avoid kwcall issues
    if bounds === nothing && auto_scale && !isempty(elements)
        # Find bounds from the single element
        min_x, max_x, min_y, max_y = get_element_bounds(element)

        # Calculate ranges
        x_range = max_x - min_x
        y_range = max_y - min_y

        # Handle constant data by providing minimum range
        min_range = 1.0f0
        if x_range < min_range
            x_range = min_range
            x_center = (max_x + min_x) / 2
            min_x = x_center - x_range / 2
            max_x = x_center + x_range / 2
        end

        if y_range < min_range
            y_range = min_range
            y_center = (max_y + min_y) / 2
            min_y = y_center - y_range / 2
            max_y = y_center + y_range / 2
        end

        calculated_bounds = Rect2f(
            min_x,
            min_y,
            (max_x - min_x),
            (max_y - min_y)
        )
    elseif bounds !== nothing
        calculated_bounds = bounds
    else
        calculated_bounds = Rect2f(0.0f0, 0.0f0, 1.0f0, 1.0f0)  # Default bounds
    end

    return PlotState(elements, calculated_bounds, auto_scale, nothing, nothing, nothing, nothing)
end

"""
Get effective bounds for plotting (considering zoom state)
"""
function get_effective_bounds(state::PlotState, style::PlotStyle)
    # Use current zoom bounds if set, otherwise fall back to initial bounds from style, then auto-calculated bounds
    x_min = something(state.current_x_min, style.initial_x_min, state.bounds.x)
    x_max = something(state.current_x_max, style.initial_x_max, state.bounds.x + state.bounds.width)
    y_min = something(state.current_y_min, style.initial_y_min, state.bounds.y)
    y_max = something(state.current_y_max, style.initial_y_max, state.bounds.y + state.bounds.height)

    return Rect2f(x_min, y_min, x_max - x_min, y_max - y_min)
end