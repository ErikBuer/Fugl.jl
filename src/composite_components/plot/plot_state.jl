struct PlotState
    bounds::Rect2f  # Plot bounds (min_x, min_y, width, height)
    auto_scale::Bool
    # Initial view bounds (for reset functionality and fixed bounds)
    initial_x_min::Union{Float32,Nothing}
    initial_x_max::Union{Float32,Nothing}
    initial_y_min::Union{Float32,Nothing}
    initial_y_max::Union{Float32,Nothing}
    # Current zoom/view bounds (for user-controlled zooming)
    current_x_min::Union{Float32,Nothing}
    current_x_max::Union{Float32,Nothing}
    current_y_min::Union{Float32,Nothing}
    current_y_max::Union{Float32,Nothing}
end

"""
Create PlotState with explicit bounds
"""
function PlotState(bounds::Rect2f; auto_scale::Bool=false)
    return PlotState(bounds, auto_scale, nothing, nothing, nothing, nothing, nothing, nothing, nothing, nothing)
end

"""
Create PlotState with sensible defaults or initial view bounds
"""
function PlotState(;
    bounds::Union{Rect2f,Nothing}=nothing,
    auto_scale::Bool=true,
    initial_x_min::Union{Float32,Nothing}=nothing,
    initial_x_max::Union{Float32,Nothing}=nothing,
    initial_y_min::Union{Float32,Nothing}=nothing,
    initial_y_max::Union{Float32,Nothing}=nothing
)
    if bounds === nothing
        bounds = Rect2f(0.0f0, 0.0f0, 1.0f0, 1.0f0)  # Default bounds
    end
    return PlotState(bounds, auto_scale, initial_x_min, initial_x_max, initial_y_min, initial_y_max, nothing, nothing, nothing, nothing)
end

"""
Calculate bounds from a vector of plot elements
"""
function calculate_bounds_from_elements(elements::Vector{AbstractPlotElement})::Rect2f
    if isempty(elements)
        return Rect2f(0.0f0, 0.0f0, 1.0f0, 1.0f0)  # Default bounds for empty elements
    end

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
            y_range = min_range
            y_center = (max_y + min_y) / 2
            min_y = y_center - y_range / 2
            max_y = y_center + y_range / 2
        end

        return Rect2f(
            min_x,
            min_y,
            (max_x - min_x),
            (max_y - min_y)
        )
    else
        return Rect2f(0.0f0, 0.0f0, 1.0f0, 1.0f0)  # Default bounds
    end
end

"""
Get effective bounds for plotting (considering zoom state)
"""
function get_effective_bounds(state::PlotState, style::PlotStyle)
    # Use current zoom bounds if set, otherwise fall back to initial bounds from state, then auto-calculated bounds
    x_min = something(state.current_x_min, state.initial_x_min, state.bounds.x)
    x_max = something(state.current_x_max, state.initial_x_max, state.bounds.x + state.bounds.width)
    y_min = something(state.current_y_min, state.initial_y_min, state.bounds.y)
    y_max = something(state.current_y_max, state.initial_y_max, state.bounds.y + state.bounds.height)

    return Rect2f(x_min, y_min, x_max - x_min, y_max - y_min)
end