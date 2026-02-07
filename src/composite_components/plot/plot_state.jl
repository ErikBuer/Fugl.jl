"""
Partial bounds specification for initial view
"""
struct PartialBounds
    x_min::Union{Float32,Nothing}
    x_max::Union{Float32,Nothing}
    y_min::Union{Float32,Nothing}
    y_max::Union{Float32,Nothing}
end

"""
    PlotState(initial_bounds, current_bounds, auto_scale, cache_id)

Represents the state of a plot, including axis bounds, scaling, and cache information.

Fields:
- `initial_bounds`: User-defined initial view bounds (preserved during drag operations). Can be Rectangle, PartialBounds, or Nothing.
- `current_bounds`: Current view bounds (after zoom/pan). If nothing, falls back to initial_bounds or auto-scale.
- `auto_scale`: Bool, whether to automatically scale axes to fit data when no bounds are specified.
- `cache_id`: Unique identifier for plot cache. Not user managed.
- `drag_cursor_position`: Plot coordinate where drag started. Not user managed.
- `is_dragging`: Whether plot is being dragged. Not user managed.
"""
struct PlotState
    # User-defined initial view bounds (preserved during drag operations)
    initial_bounds::Union{Rectangle,PartialBounds,Nothing}
    # Current zoom/view bounds (for user-controlled zooming)
    current_bounds::Union{Rectangle,Nothing}
    auto_scale::Bool
    # Cache ID for render caching
    cache_id::UInt64
    # Drag state tracking
    drag_cursor_position::Union{Nothing,Tuple{Float32,Float32}}
    is_dragging::Bool
end

"""
Create a new PlotState from an existing state with keyword-based modifications.
"""
function PlotState(state::PlotState;
    initial_bounds=state.initial_bounds,
    current_bounds=state.current_bounds,
    auto_scale=state.auto_scale,
    cache_id=state.cache_id, # Not user managed
    drag_cursor_position=state.drag_cursor_position, # Not user managed
    is_dragging=state.is_dragging # Not user managed
)
    return PlotState(
        initial_bounds,
        current_bounds,
        auto_scale,
        cache_id,
        drag_cursor_position,
        is_dragging
    )
end

"""
Create PlotState with explicit bounds
"""
function PlotState(bounds::Rectangle; auto_scale::Bool=false)
    return PlotState(bounds, nothing, auto_scale, generate_cache_id(), nothing, false)
end

"""
Create PlotState with sensible defaults or initial view bounds
"""
function PlotState(;
    auto_scale::Bool=true,
    x_min::Union{Float32,Nothing}=nothing,
    x_max::Union{Float32,Nothing}=nothing,
    y_min::Union{Float32,Nothing}=nothing,
    y_max::Union{Float32,Nothing}=nothing
)
    initial_bounds::Union{Rectangle,PartialBounds,Nothing} = nothing

    # Convert individual x_min/x_max/y_min/y_max params to initial_bounds if provided
    if !isnothing(x_min) || !isnothing(x_max) ||
       !isnothing(y_min) || !isnothing(y_max)

        # Check if we have complete bounds for a Rectangle
        if !isnothing(x_min) && !isnothing(x_max) &&
           !isnothing(y_min) && !isnothing(y_max)
            initial_bounds = Rectangle(x_min, y_min,
                x_max - x_min,
                y_max - y_min)
        else
            # Use PartialBounds for partial specification
            initial_bounds = PartialBounds(x_min, x_max, y_min, y_max)
        end
    end

    return PlotState(initial_bounds, nothing, auto_scale, generate_cache_id(), nothing, false)
end

"""
Calculate bounds from a vector of plot elements
"""
function calculate_bounds_from_elements(elements::Vector{AbstractPlotElement})::Rectangle
    if isempty(elements)
        return Rectangle(0.0f0, 0.0f0, 1.0f0, 1.0f0)  # Default bounds for empty elements
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

        return Rectangle(
            min_x,
            min_y,
            (max_x - min_x),
            (max_y - min_y)
        )
    else
        return Rectangle(0.0f0, 0.0f0, 1.0f0, 1.0f0)  # Default bounds
    end
end

"""
Get effective bounds for plotting (considering zoom state)
Priority: current_bounds -> initial_bounds (with partial bounds support) -> auto-calculated from elements
"""
function get_effective_bounds(state::PlotState, elements::Vector{AbstractPlotElement})
    # Priority 1: Current bounds (after zoom/pan)
    if !isnothing(state.current_bounds)
        return state.current_bounds
    end

    # Priority 2: Initial bounds (user-defined)
    if !isnothing(state.initial_bounds)
        if state.initial_bounds isa Rectangle
            # Complete bounds specified
            return state.initial_bounds
        elseif state.initial_bounds isa PartialBounds
            # Partial bounds - merge with auto-calculated bounds
            auto_bounds = calculate_bounds_from_elements(elements)
            partial = state.initial_bounds

            # Extract values from auto_bounds
            auto_x_min = auto_bounds.x
            auto_y_min = auto_bounds.y
            auto_x_max = auto_x_min + auto_bounds.width
            auto_y_max = auto_y_min + auto_bounds.height

            # Use user-specified bounds where provided, auto-calculated otherwise
            final_x_min = isnothing(partial.x_min) ? auto_x_min : partial.x_min
            final_x_max = isnothing(partial.x_max) ? auto_x_max : partial.x_max
            final_y_min = isnothing(partial.y_min) ? auto_y_min : partial.y_min
            final_y_max = isnothing(partial.y_max) ? auto_y_max : partial.y_max

            return Rectangle(
                final_x_min,
                final_y_min,
                final_x_max - final_x_min,
                final_y_max - final_y_min
            )
        end
    end

    # Priority 3: Auto-calculated from elements
    return calculate_bounds_from_elements(elements)
end

"""
    reset_plot_view_bounds(state::PlotState)

Returns a copy of the PlotState with current_bounds reset to nothing, falling back to initial_bounds.
"""
function reset_plot_view_bounds(state::PlotState)
    return PlotState(state; current_bounds=nothing)
end