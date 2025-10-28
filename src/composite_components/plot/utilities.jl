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