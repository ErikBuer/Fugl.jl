struct LineBatch
    points::Vector{Point2f}        # All line points
    colors::Vector{Vec4{Float32}}   # Color per point (for gradients)
    widths::Vector{Float32}        # Width per point (for variable thickness)
    line_styles::Vector{Float32}   # Line style per point (0=solid, 1=dash, 2=dot, 3=dashdot)
    line_progresses::Vector{Float32} # Cumulative distance along line for dash patterns
    segment_starts::Vector{Int32}  # Start indices for each line segment
    segment_lengths::Vector{Int32} # Length of each line segment
end

function LineBatch()
    return LineBatch(
        Point2f[],
        Vec4{Float32}[],
        Float32[],
        Float32[],
        Float32[],
        Int32[],
        Int32[]
    )
end

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

# Add a complete line (series of connected points) to the batch
function add_line!(batch::LineBatch, points::Vector{Point2f}, color::Vec4{Float32}, width::Float32, line_style::Float32=0.0f0)
    if length(points) < 2
        return  # Need at least 2 points for a line
    end

    start_idx = length(batch.points) + 1

    # Calculate progress along this line
    line_progress = calculate_line_progress(points)

    # Add all points
    append!(batch.points, points)

    # Add color, width, line style, and progress for each point
    for i in 1:length(points)
        push!(batch.colors, color)
        push!(batch.widths, width)
        push!(batch.line_styles, line_style)
        push!(batch.line_progresses, line_progress[i])
    end

    # Record this line segment
    push!(batch.segment_starts, Int32(start_idx))
    push!(batch.segment_lengths, Int32(length(points)))
end

# Optimized line drawing using enhanced shader with line style support
function draw_line_plot(
    x_data::Vector{Float32},
    y_data::Vector{Float32},
    transform_func::Function,
    color::Vec4{Float32},
    width::Float32,
    line_style::Float32,
    projection_matrix::Mat4{Float32}
)
    if length(x_data) != length(y_data) || length(x_data) < 2
        return
    end

    # Transform data points to screen coordinates
    screen_points = Vector{Point2f}()
    sizehint!(screen_points, length(x_data))

    for i in 1:length(x_data)
        screen_x, screen_y = transform_func(x_data[i], y_data[i])
        push!(screen_points, Point2f(screen_x, screen_y))
    end

    # Create batch and add this line
    batch = LineBatch()
    add_line!(batch, screen_points, color, width, line_style)

    # Draw the batch
    draw_lines_enhanced(batch, projection_matrix)
end

# Enhanced line drawing using efficient method (keeping old interface but with optimizations)
function draw_lines_enhanced(batch::LineBatch, projection_matrix::Mat4{Float32})
    if isempty(batch.points)
        return
    end

    # Use the existing line shader program that works
    GLA.bind(line_prog[])

    # Set uniforms
    GLA.gluniform(line_prog[], :projection, projection_matrix)

    # Use the much more efficient approach: fewer triangles, batch processing
    all_positions = Vector{Point2f}()
    all_directions = Vector{Point2f}()
    all_widths = Vector{Float32}()
    all_colors = Vector{Vec4{Float32}}()
    all_vertex_types = Vector{Float32}()
    all_line_styles = Vector{Float32}()
    all_line_progresses = Vector{Float32}()

    # Process all segments in one go (more efficient)
    for seg_idx in 1:length(batch.segment_starts)
        start_idx = batch.segment_starts[seg_idx]
        length_seg = batch.segment_lengths[seg_idx]
        end_idx = start_idx + length_seg - 1

        if length_seg < 2
            continue
        end

        line_points = batch.points[start_idx:end_idx]
        line_color = batch.colors[start_idx]
        line_width = batch.widths[start_idx]
        line_style = batch.line_styles[start_idx]
        line_progresses = batch.line_progresses[start_idx:end_idx]

        # Generate efficient line geometry (minimal triangles)
        seg_positions, seg_directions, seg_widths, seg_colors, seg_vertex_types, seg_line_styles, seg_progresses =
            generate_efficient_line_geometry(line_points, line_color, line_width, line_style, line_progresses)

        append!(all_positions, seg_positions)
        append!(all_directions, seg_directions)
        append!(all_widths, seg_widths)
        append!(all_colors, seg_colors)
        append!(all_vertex_types, seg_vertex_types)
        append!(all_line_styles, seg_line_styles)
        append!(all_line_progresses, seg_progresses)
    end

    if isempty(all_positions)
        GLA.unbind(line_prog[])
        return
    end

    # Generate buffers using GLAbstraction
    buffers = GLA.generate_buffers(
        line_prog[],
        position=all_positions,
        direction=all_directions,
        width=all_widths,
        color=all_colors,
        vertex_type=all_vertex_types,
        line_style=all_line_styles,
        line_progress=all_line_progresses
    )

    # Create VAO and draw
    vao = GLA.VertexArray(buffers)

    GLA.bind(vao)
    GLA.draw(vao)
    GLA.unbind(vao)

    # Unbind shader program
    GLA.unbind(line_prog[])
end

# Generate efficient line geometry - minimal triangles, optimized for performance
function generate_efficient_line_geometry(points::Vector{Point2f}, color::Vec4{Float32}, width::Float32, line_style::Float32, line_progresses::Vector{Float32})
    positions = Vector{Point2f}()
    directions = Vector{Point2f}()
    widths = Vector{Float32}()
    colors = Vector{Vec4{Float32}}()
    vertex_types = Vector{Float32}()
    line_styles = Vector{Float32}()
    line_progresses_out = Vector{Float32}()

    if length(points) < 2 || length(line_progresses) != length(points)
        return positions, directions, widths, colors, vertex_types, line_styles, line_progresses_out
    end

    # Pre-allocate for efficiency (2 triangles = 6 vertices per segment)
    num_segments = length(points) - 1
    sizehint!(positions, num_segments * 6)
    sizehint!(directions, num_segments * 6)
    sizehint!(widths, num_segments * 6)
    sizehint!(colors, num_segments * 6)
    sizehint!(vertex_types, num_segments * 6)
    sizehint!(line_styles, num_segments * 6)
    sizehint!(line_progresses_out, num_segments * 6)

    # Efficiently generate geometry for each segment 
    for i in 1:(length(points)-1)
        start_point = points[i]
        end_point = points[i+1]
        start_progress = line_progresses[i]
        end_progress = line_progresses[i+1]

        # Calculate direction vector for current segment
        direction_vec = Point2f(end_point[1] - start_point[1], end_point[2] - start_point[2])

        # Generate 2 triangles (6 vertices) for this segment - no overlap needed for efficiency
        # Triangle 1: bottom-left, bottom-right, top-left
        append!(positions, [start_point, start_point, start_point])
        append!(directions, [direction_vec, direction_vec, direction_vec])
        append!(widths, [width, width, width])
        append!(colors, [color, color, color])
        append!(vertex_types, [0.0f0, 1.0f0, 2.0f0])  # bottom-left, bottom-right, top-left
        append!(line_styles, [line_style, line_style, line_style])
        append!(line_progresses_out, [start_progress, end_progress, start_progress])

        # Triangle 2: bottom-right, top-right, top-left
        append!(positions, [start_point, start_point, start_point])
        append!(directions, [direction_vec, direction_vec, direction_vec])
        append!(widths, [width, width, width])
        append!(colors, [color, color, color])
        append!(vertex_types, [1.0f0, 3.0f0, 2.0f0])  # bottom-right, top-right, top-left
        append!(line_styles, [line_style, line_style, line_style])
        append!(line_progresses_out, [end_progress, end_progress, start_progress])
    end

    return positions, directions, widths, colors, vertex_types, line_styles, line_progresses_out
end

# Generate enhanced line geometry with line style support and progress calculation
function generate_enhanced_line_geometry(points::Vector{Point2f}, color::Vec4{Float32}, width::Float32, line_style::Float32)
    positions = Vector{Point2f}()
    directions = Vector{Point2f}()
    widths = Vector{Float32}()
    colors = Vector{Vec4{Float32}}()
    vertex_types = Vector{Float32}()
    line_styles = Vector{Float32}()
    line_progresses = Vector{Float32}()

    if length(points) < 2
        return positions, directions, widths, colors, vertex_types, line_styles, line_progresses
    end

    # Calculate cumulative distance along the line for pattern progress
    cumulative_distance = 0.0f0
    distances = Float32[0.0f0]  # Start at 0

    for i in 2:length(points)
        segment_length = norm(points[i] - points[i-1])
        cumulative_distance += segment_length
        push!(distances, cumulative_distance)
    end

    # For each line segment, generate geometry with slight overlaps and progress info
    for i in 1:(length(points)-1)
        start_point = points[i]
        end_point = points[i+1]
        start_progress = distances[i]
        end_progress = distances[i+1]

        # Calculate direction vector for current segment
        direction_vec = Point2f(end_point[1] - start_point[1], end_point[2] - start_point[2])

        # Slight overlap for crack elimination
        actual_start = start_point
        actual_end = end_point
        actual_start_progress = start_progress
        actual_end_progress = end_progress

        if i > 1
            # Extend start point slightly backwards
            if norm(direction_vec) > 0
                dir_norm = direction_vec / norm(direction_vec)
                overlap = width * 0.1f0
                actual_start = Point2f(start_point[1] - dir_norm[1] * overlap,
                    start_point[2] - dir_norm[2] * overlap)
                actual_start_progress = start_progress - overlap
            end
        end

        if i < length(points) - 1
            # Extend end point slightly forward
            if norm(direction_vec) > 0
                dir_norm = direction_vec / norm(direction_vec)
                overlap = width * 0.1f0
                actual_end = Point2f(end_point[1] + dir_norm[1] * overlap,
                    end_point[2] + dir_norm[2] * overlap)
                actual_end_progress = end_progress + overlap
            end
        end

        # Recalculate direction with adjusted endpoints
        adjusted_direction = Point2f(actual_end[1] - actual_start[1], actual_end[2] - actual_start[2])

        # Generate quad vertices (2 triangles = 6 vertices)
        # Triangle 1: bottom-left, bottom-right, top-left
        push!(positions, actual_start, actual_start, actual_start)
        push!(directions, adjusted_direction, adjusted_direction, adjusted_direction)
        push!(widths, width, width, width)
        push!(colors, color, color, color)
        push!(vertex_types, 0.0f0, 1.0f0, 2.0f0)  # bottom-left, bottom-right, top-left
        push!(line_styles, line_style, line_style, line_style)
        push!(line_progresses, actual_start_progress, actual_end_progress, actual_start_progress)

        # Triangle 2: bottom-right, top-right, top-left
        push!(positions, actual_start, actual_start, actual_start)
        push!(directions, adjusted_direction, adjusted_direction, adjusted_direction)
        push!(widths, width, width, width)
        push!(colors, color, color, color)
        push!(vertex_types, 1.0f0, 3.0f0, 2.0f0)  # bottom-right, top-right, top-left
        push!(line_styles, line_style, line_style, line_style)
        push!(line_progresses, actual_end_progress, actual_end_progress, actual_start_progress)
    end

    return positions, directions, widths, colors, vertex_types, line_styles, line_progresses
end

# Generate simple line geometry - quad-based with proper joins to eliminate cracks (legacy function)
function generate_simple_line_geometry(points::Vector{Point2f}, color::Vec4{Float32}, width::Float32)
    positions = Vector{Point2f}()
    directions = Vector{Point2f}()
    widths = Vector{Float32}()
    colors = Vector{Vec4{Float32}}()
    vertex_types = Vector{Float32}()

    if length(points) < 2
        return positions, directions, widths, colors, vertex_types
    end

    # For each line segment, generate geometry with slight overlaps to eliminate cracks
    for i in 1:(length(points)-1)
        start_point = points[i]
        end_point = points[i+1]

        # Calculate direction vector for current segment
        direction_vec = Point2f(end_point[1] - start_point[1], end_point[2] - start_point[2])

        # Slight overlap for crack elimination
        actual_start = start_point
        actual_end = end_point

        if i > 1
            # Extend start point slightly backwards
            if norm(direction_vec) > 0
                dir_norm = direction_vec / norm(direction_vec)
                actual_start = Point2f(start_point[1] - dir_norm[1] * width * 0.1f0,
                    start_point[2] - dir_norm[2] * width * 0.1f0)
            end
        end

        if i < length(points) - 1
            # Extend end point slightly forward
            if norm(direction_vec) > 0
                dir_norm = direction_vec / norm(direction_vec)
                actual_end = Point2f(end_point[1] + dir_norm[1] * width * 0.1f0,
                    end_point[2] + dir_norm[2] * width * 0.1f0)
            end
        end

        # Recalculate direction with adjusted endpoints
        adjusted_direction = Point2f(actual_end[1] - actual_start[1], actual_end[2] - actual_start[2])

        # Generate quad vertices (2 triangles = 6 vertices)
        # Triangle 1: bottom-left, bottom-right, top-left
        push!(positions, actual_start, actual_start, actual_start)
        push!(directions, adjusted_direction, adjusted_direction, adjusted_direction)
        push!(widths, width, width, width)
        push!(colors, color, color, color)
        push!(vertex_types, 0.0f0, 1.0f0, 2.0f0)  # bottom-left, bottom-right, top-left

        # Triangle 2: bottom-right, top-right, top-left
        push!(positions, actual_start, actual_start, actual_start)
        push!(directions, adjusted_direction, adjusted_direction, adjusted_direction)
        push!(widths, width, width, width)
        push!(colors, color, color, color)
        push!(vertex_types, 1.0f0, 3.0f0, 2.0f0)  # bottom-right, top-right, top-left
    end

    return positions, directions, widths, colors, vertex_types
end

# Grid and axis rendering functions using the enhanced line shader

"""
Draw a grid with specified parameters using the enhanced line shader
"""
function draw_grid(
    plot_bounds::Rect2f,
    x_ticks::Vector{Float32},
    y_ticks::Vector{Float32},
    transform_func::Function,
    color::Vec4{Float32},
    width::Float32,
    line_style::Float32,
    projection_matrix::Mat4{Float32}
)
    batch = LineBatch()

    # Draw vertical grid lines (constant x, varying y)
    for x_tick in x_ticks
        if x_tick >= plot_bounds.x && x_tick <= plot_bounds.x + plot_bounds.width
            # Transform start and end points
            start_screen_x, start_screen_y = transform_func(x_tick, plot_bounds.y)
            end_screen_x, end_screen_y = transform_func(x_tick, plot_bounds.y + plot_bounds.height)

            grid_points = [Point2f(start_screen_x, start_screen_y), Point2f(end_screen_x, end_screen_y)]
            add_line!(batch, grid_points, color, width, line_style)
        end
    end

    # Draw horizontal grid lines (constant y, varying x)
    for y_tick in y_ticks
        if y_tick >= plot_bounds.y && y_tick <= plot_bounds.y + plot_bounds.height
            # Transform start and end points
            start_screen_x, start_screen_y = transform_func(plot_bounds.x, y_tick)
            end_screen_x, end_screen_y = transform_func(plot_bounds.x + plot_bounds.width, y_tick)

            grid_points = [Point2f(start_screen_x, start_screen_y), Point2f(end_screen_x, end_screen_y)]
            add_line!(batch, grid_points, color, width, line_style)
        end
    end

    # Draw all grid lines
    draw_lines_enhanced(batch, projection_matrix)
end

"""
Draw axes (x and y axis lines) using the enhanced line shader
"""
function draw_axes(
    plot_bounds::Rect2f,
    transform_func::Function,
    color::Vec4{Float32},
    width::Float32,
    projection_matrix::Mat4{Float32}
)
    batch = LineBatch()

    # X-axis (y = 0, if 0 is within bounds)
    if 0.0f0 >= plot_bounds.y && 0.0f0 <= plot_bounds.y + plot_bounds.height
        start_screen_x, start_screen_y = transform_func(plot_bounds.x, 0.0f0)
        end_screen_x, end_screen_y = transform_func(plot_bounds.x + plot_bounds.width, 0.0f0)

        x_axis_points = [Point2f(start_screen_x, start_screen_y), Point2f(end_screen_x, end_screen_y)]
        add_line!(batch, x_axis_points, color, width, 0.0f0)  # Solid line for axes
    end

    # Y-axis (x = 0, if 0 is within bounds)
    if 0.0f0 >= plot_bounds.x && 0.0f0 <= plot_bounds.x + plot_bounds.width
        start_screen_x, start_screen_y = transform_func(0.0f0, plot_bounds.y)
        end_screen_x, end_screen_y = transform_func(0.0f0, plot_bounds.y + plot_bounds.height)

        y_axis_points = [Point2f(start_screen_x, start_screen_y), Point2f(end_screen_x, end_screen_y)]
        add_line!(batch, y_axis_points, color, width, 0.0f0)  # Solid line for axes
    end

    # Draw all axis lines
    draw_lines_enhanced(batch, projection_matrix)
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
