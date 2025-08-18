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