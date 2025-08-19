"""
Helper function to extract data bounds from any plot element
"""
function get_element_bounds(element::AbstractPlotElement)::Tuple{Float32,Float32,Float32,Float32}
    if element isa LinePlotElement || element isa ScatterPlotElement || element isa StemPlotElement
        if !isempty(element.x_data) && !isempty(element.y_data)
            min_x, max_x = extrema(element.x_data)
            min_y, max_y = extrema(element.y_data)
            return (min_x, max_x, min_y, max_y)
        end
    elseif element isa HeatmapElement
        min_x, max_x = element.x_range
        min_y, max_y = element.y_range
        return (min_x, max_x, min_y, max_y)
    elseif element isa VerticalColorbar
        # For vertical colorbar: thin width (0-1), height matches value range
        min_val, max_val = element.value_range
        return (0.0f0, 1.0f0, min_val, max_val)
    elseif element isa HorizontalColorbar
        # For horizontal colorbar: width matches value range, thin height (0-1)
        min_val, max_val = element.value_range
        return (min_val, max_val, 0.0f0, 1.0f0)
    end
    return (0.0f0, 1.0f0, 0.0f0, 1.0f0)  # Default bounds
end

"""
Calculate cumulative distance along a line defined by points.
"""
function calculate_line_progress(points::Vector{Point2f})::Vector{Float32}
    if length(points) < 2
        return Float32[]
    end

    progress = Vector{Float32}(undef, length(points))
    progress[1] = 0.0f0

    for i in 2:length(points)
        segment_length = norm(points[i] - points[i-1])
        progress[i] = progress[i-1] + segment_length
    end

    return progress
end

"""
Generate reasonable tick positions for a given range
"""
function generate_tick_positions(min_val::Float32, max_val::Float32, approx_num_ticks::Int=8)::Vector{Float32}
    if min_val >= max_val
        return Float32[]
    end

    range_val = max_val - min_val
    # Find a nice step size
    raw_step = range_val / approx_num_ticks

    # Round to a nice number
    magnitude = 10.0f0^floor(log10(raw_step))
    normalized_step = raw_step / magnitude

    nice_step = if normalized_step <= 1.0f0
        1.0f0
    elseif normalized_step <= 2.0f0
        2.0f0
    elseif normalized_step <= 5.0f0
        5.0f0
    else
        10.0f0
    end

    step = nice_step * magnitude

    # Generate ticks
    ticks = Float32[]
    start_tick = ceil(min_val / step) * step

    current_tick = start_tick
    while current_tick <= max_val
        push!(ticks, current_tick)
        current_tick += step
    end

    return ticks
end