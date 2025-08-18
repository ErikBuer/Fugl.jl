"""
Struct for storing a batch of lines for efficient drawing.
"""
struct LineBatch
    points::Vector{Point2f}          # All line points
    colors::Vector{Vec4{Float32}}    # Color per point (for gradients)
    widths::Vector{Float32}          # Width per point (for variable thickness)
    line_styles::Vector{Float32}     # Line style per point (enum as Float32). Int somehow doesn't work on all targets.
    line_progresses::Vector{Float32} # Cumulative distance along line for dash patterns
    segment_starts::Vector{Int32}    # Start indices for each line segment
    segment_lengths::Vector{Int32}   # Length of each line segment
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

"""
Split line data at NaN values into separate continuous segments.
Returns a vector of (x_segment, y_segment) tuples.
"""
function split_line_at_nan(x_data::Vector{Float32}, y_data::Vector{Float32})
    segments = Tuple{Vector{Float32},Vector{Float32}}[]

    if length(x_data) != length(y_data) || isempty(x_data)
        return segments
    end

    current_x = Float32[]
    current_y = Float32[]

    for i in 1:length(x_data)
        x_val = x_data[i]
        y_val = y_data[i]

        if isnan(x_val) || isnan(y_val)
            # NaN encountered - finish current segment if it has data
            if length(current_x) >= 2
                push!(segments, (copy(current_x), copy(current_y)))
            end
            # Start new segment
            empty!(current_x)
            empty!(current_y)
        else
            # Add point to current segment
            push!(current_x, x_val)
            push!(current_y, y_val)
        end
    end

    # Add final segment if it has data
    if length(current_x) >= 2
        push!(segments, (copy(current_x), copy(current_y)))
    end

    return segments
end

# Add a complete line (series of connected points) to the batch
function add_line!(batch::LineBatch, points::Vector{Point2f}, color::Vec4{Float32}, width::Float32, line_style::LineStyle=SOLID)
    if length(points) < 2
        return  # Need at least 2 points for a line
    end

    start_idx = length(batch.points) + 1

    # Calculate progress along this line
    line_progress = calculate_line_progress(points)

    # Add all points
    append!(batch.points, points)

    # Add color, width, line style, and progress for each point
    # Convert enum to Float32 for shader
    # Int somehow doesn't work on all targets.
    line_style_f32 = Float32(line_style)
    for i in 1:length(points)
        push!(batch.colors, color)
        push!(batch.widths, width)
        push!(batch.line_styles, line_style_f32)
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
    line_style::LineStyle,
    projection_matrix::Mat4{Float32};
    anti_aliasing_width::Float32=1.5f0
)
    if length(x_data) != length(y_data) || length(x_data) < 2
        return
    end

    # Create batch
    batch = LineBatch()

    # Split data at NaN values and process each segment separately
    segments = split_line_at_nan(x_data, y_data)

    for (seg_x, seg_y) in segments
        if length(seg_x) >= 2  # Need at least 2 points for a line
            # Transform data points to screen coordinates
            screen_points = Vector{Point2f}()
            sizehint!(screen_points, length(seg_x))

            for i in 1:length(seg_x)
                screen_x, screen_y = transform_func(seg_x[i], seg_y[i])
                push!(screen_points, Point2f(screen_x, screen_y))
            end

            # Add this line segment to the batch
            add_line!(batch, screen_points, color, width, line_style)
        end
    end

    # Draw the batch
    draw_lines(batch, projection_matrix; anti_aliasing_width=anti_aliasing_width)
end

"""
Batched line drawing function.
"""
function draw_lines(batch::LineBatch, projection_matrix::Mat4{Float32}; anti_aliasing_width::Float32=1.5f0)
    if isempty(batch.points)
        return
    end

    # Use the existing line shader program that works
    GLA.bind(line_prog[])

    # Set uniforms
    GLA.gluniform(line_prog[], :projection, projection_matrix)
    GLA.gluniform(line_prog[], :anti_aliasing_width, anti_aliasing_width)

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
        line_style_f32 = batch.line_styles[start_idx]
        line_style = LineStyle(Int(line_style_f32))  # Convert back to enum for function call
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
function generate_efficient_line_geometry(points::Vector{Point2f}, color::Vec4{Float32}, width::Float32, line_style::LineStyle, line_progresses::Vector{Float32})
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

    # Convert enum to Float32 for shader compatibility
    # Int somehow doesn't work on all targets.
    line_style_f32 = Float32(line_style)

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
        append!(line_styles, [line_style_f32, line_style_f32, line_style_f32])
        append!(line_progresses_out, [start_progress, end_progress, start_progress])

        # Triangle 2: bottom-right, top-right, top-left
        append!(positions, [start_point, start_point, start_point])
        append!(directions, [direction_vec, direction_vec, direction_vec])
        append!(widths, [width, width, width])
        append!(colors, [color, color, color])
        append!(vertex_types, [1.0f0, 3.0f0, 2.0f0])  # bottom-right, top-right, top-left
        append!(line_styles, [line_style_f32, line_style_f32, line_style_f32])
        append!(line_progresses_out, [end_progress, end_progress, start_progress])
    end

    return positions, directions, widths, colors, vertex_types, line_styles, line_progresses_out
end

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
    line_style::LineStyle,
    projection_matrix::Mat4{Float32};
    anti_aliasing_width::Float32=1.5f0
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
    draw_lines(batch, projection_matrix; anti_aliasing_width=anti_aliasing_width)
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
Draw a grid with axis lines using both enhanced line shader
Grid lines and axis lines are positioned at plot edges (left/bottom), not at zero lines
Labels are handled separately by draw_axes_with_labels
"""
function draw_grid_with_labels(
    plot_bounds::Rect2f,
    x_ticks::Vector{Float32},
    y_ticks::Vector{Float32},
    transform_func::Function,
    screen_bounds::Rect2f,
    color::Vec4{Float32},
    width::Float32,
    line_style::LineStyle,
    projection_matrix::Mat4{Float32};
    label_size_px::Int=12,
    label_color::Vec4{Float32}=Vec4{Float32}(0.0, 0.0, 0.0, 1.0),
    label_offset_px::Float32=5.0f0,
    axis_color::Vec4{Float32}=Vec4{Float32}(0.0, 0.0, 0.0, 1.0),
    axis_width::Float32=2.0f0,
    anti_aliasing_width::Float32=1.5f0
)
    # Draw the grid lines (including x=0, y=0 if in bounds)
    draw_grid(plot_bounds, x_ticks, y_ticks, transform_func, color, width, line_style, projection_matrix; anti_aliasing_width=anti_aliasing_width)

    # Draw axis lines at plot edges (left and bottom edges) - no labels, those are handled by draw_axes_with_labels
    axis_batch = LineBatch()

    # Bottom edge axis line (horizontal line at bottom of plot)
    bottom_y = plot_bounds.y
    bottom_start_x, bottom_start_y = transform_func(plot_bounds.x, bottom_y)
    bottom_end_x, bottom_end_y = transform_func(plot_bounds.x + plot_bounds.width, bottom_y)
    bottom_axis_points = [Point2f(bottom_start_x, bottom_start_y), Point2f(bottom_end_x, bottom_end_y)]
    add_line!(axis_batch, bottom_axis_points, axis_color, axis_width, SOLID)  # Solid line

    # Left edge axis line (vertical line at left of plot)
    left_x = plot_bounds.x
    left_start_x, left_start_y = transform_func(left_x, plot_bounds.y)
    left_end_x, left_end_y = transform_func(left_x, plot_bounds.y + plot_bounds.height)
    left_axis_points = [Point2f(left_start_x, left_start_y), Point2f(left_end_x, left_end_y)]
    add_line!(axis_batch, left_axis_points, axis_color, axis_width, SOLID)  # Solid line

    # Draw the axis lines only (no labels - those are handled by draw_axes_with_labels)
    draw_lines(axis_batch, projection_matrix; anti_aliasing_width=anti_aliasing_width)
end

"""
Draw axes with labels and tick marks using both lines and Text components
Axis lines, tick marks, and labels are positioned at plot edges (left/bottom), not at zero lines
"""
function draw_axes_with_labels(
    plot_bounds::Rect2f,
    x_ticks::Vector{Float32},
    y_ticks::Vector{Float32},
    transform_func::Function,
    screen_bounds::Rect2f,
    color::Vec4{Float32},
    width::Float32,
    projection_matrix::Mat4{Float32};
    label_size_px::Int=12,
    label_color::Vec4{Float32}=Vec4{Float32}(0.0, 0.0, 0.0, 1.0),
    label_offset_px::Float32=5.0f0,
    axis_color::Vec4{Float32}=Vec4{Float32}(0.0, 0.0, 0.0, 1.0),
    axis_width::Float32=2.0f0,
    tick_length_px::Float32=8.0f0,
    anti_aliasing_width::Float32=1.5f0
)
    # Draw axis lines and tick marks at plot edges (left and bottom edges)
    axis_batch = LineBatch()

    # Bottom edge axis line (horizontal line at bottom of plot)
    bottom_y = plot_bounds.y
    bottom_start_x, bottom_start_y = transform_func(plot_bounds.x, bottom_y)
    bottom_end_x, bottom_end_y = transform_func(plot_bounds.x + plot_bounds.width, bottom_y)
    bottom_axis_points = [Point2f(bottom_start_x, bottom_start_y), Point2f(bottom_end_x, bottom_end_y)]
    add_line!(axis_batch, bottom_axis_points, axis_color, axis_width, SOLID)  # Solid line

    # Left edge axis line (vertical line at left of plot)
    left_x = plot_bounds.x
    left_start_x, left_start_y = transform_func(left_x, plot_bounds.y)
    left_end_x, left_end_y = transform_func(left_x, plot_bounds.y + plot_bounds.height)
    left_axis_points = [Point2f(left_start_x, left_start_y), Point2f(left_end_x, left_end_y)]
    add_line!(axis_batch, left_axis_points, axis_color, axis_width, SOLID)  # Solid line

    # Add tick marks for x-axis
    for x_tick in x_ticks
        if x_tick >= plot_bounds.x && x_tick <= plot_bounds.x + plot_bounds.width
            # Transform tick position to screen coordinates (at bottom edge)
            tick_screen_x, tick_screen_y = transform_func(x_tick, plot_bounds.y)

            # Create small vertical tick mark
            tick_start = Point2f(tick_screen_x, tick_screen_y)
            tick_end = Point2f(tick_screen_x, tick_screen_y - tick_length_px)
            tick_points = [tick_start, tick_end]
            add_line!(axis_batch, tick_points, axis_color, axis_width, SOLID)
        end
    end

    # Add tick marks for y-axis
    for y_tick in y_ticks
        if y_tick >= plot_bounds.y && y_tick <= plot_bounds.y + plot_bounds.height
            # Transform tick position to screen coordinates (at left edge)
            tick_screen_x, tick_screen_y = transform_func(plot_bounds.x, y_tick)

            # Create small horizontal tick mark
            tick_start = Point2f(tick_screen_x, tick_screen_y)
            tick_end = Point2f(tick_screen_x + tick_length_px, tick_screen_y)
            tick_points = [tick_start, tick_end]
            add_line!(axis_batch, tick_points, axis_color, axis_width, SOLID)
        end
    end

    # Draw the axis lines and tick marks
    draw_lines(axis_batch, projection_matrix; anti_aliasing_width=anti_aliasing_width)

    # Create text style for labels
    text_style = TextStyle(size_px=label_size_px, color=label_color)

    # Draw x-axis labels along the bottom edge (outside plot area)
    for x_tick in x_ticks
        if x_tick >= plot_bounds.x && x_tick <= plot_bounds.x + plot_bounds.width
            # Transform tick position to screen coordinates (at bottom edge)
            tick_screen_x, tick_screen_y = transform_func(x_tick, plot_bounds.y)

            # Format the number
            label_text = if x_tick == round(x_tick)
                string(Int(round(x_tick)))
            else
                string(round(x_tick, digits=2))
            end

            # Create Text component and measure it
            text_component = Text(label_text, style=text_style, horizontal_align=:center, vertical_align=:top)
            text_width, text_height = measure(text_component)

            # Position label below the bottom axis line and tick mark, outside plot area
            label_x = tick_screen_x - text_width / 2.0f0
            label_y = tick_screen_y + tick_length_px + label_offset_px  # Below tick mark

            # Render the text component
            interpret_view(text_component, label_x, label_y, text_width, text_height, projection_matrix)
        end
    end

    # Draw y-axis labels along the left edge (outside plot area)
    for y_tick in y_ticks
        if y_tick >= plot_bounds.y && y_tick <= plot_bounds.y + plot_bounds.height
            # Transform tick position to screen coordinates (at left edge)
            tick_screen_x, tick_screen_y = transform_func(plot_bounds.x, y_tick)

            # Format the number
            label_text = if y_tick == round(y_tick)
                string(Int(round(y_tick)))
            else
                string(round(y_tick, digits=2))
            end

            # Create Text component and measure it
            text_component = Text(label_text, style=text_style, horizontal_align=:right, vertical_align=:middle)
            text_width, text_height = measure(text_component)

            # Position label to the left of the left axis line and tick mark, outside plot area
            label_x = tick_screen_x - tick_length_px - text_width - label_offset_px  # Left of tick mark
            label_y = tick_screen_y - text_height / 2.0f0  # Centered vertically on tick

            # Render the text component
            interpret_view(text_component, label_x, label_y, text_width, text_height, projection_matrix)
        end
    end
end
