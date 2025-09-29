include("line_batch.jl")

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
    GLA.bind(plot_line_prog[])

    # Set uniforms
    GLA.gluniform(plot_line_prog[], :projection, projection_matrix)
    GLA.gluniform(plot_line_prog[], :anti_aliasing_width, anti_aliasing_width)

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
        GLA.unbind(plot_line_prog[])
        return
    end

    # Generate buffers using GLAbstraction
    buffers = GLA.generate_buffers(
        plot_line_prog[],
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
    GLA.unbind(plot_line_prog[])
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
    plot_bounds::Rectangle,
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
Draw axes with labels and tick marks using both lines and Text components
Axis lines, tick marks, and labels are positioned at plot edges (left/bottom), not at zero lines
"""
function draw_axes_with_labels(
    plot_bounds::Rectangle,
    x_ticks::Vector{Float32},
    y_ticks::Vector{Float32},
    transform_func::Function,
    screen_bounds::Rectangle,
    color::Vec4{Float32},
    width::Float32,
    projection_matrix::Mat4{Float32};
    label_size_px::Int=12,
    label_color::Vec4{Float32}=Vec4{Float32}(0.0, 0.0, 0.0, 1.0),
    label_offset_px::Float32=5.0f0,
    axis_color::Vec4{Float32}=Vec4{Float32}(0.0, 0.0, 0.0, 1.0),
    axis_width::Float32=2.0f0,
    tick_length_px::Float32=8.0f0,
    anti_aliasing_width::Float32=1.5f0,
    show_left_axis::Bool=true,
    show_right_axis::Bool=false,
    show_top_axis::Bool=false,
    show_bottom_axis::Bool=true,
    show_x_tick_marks::Bool=true,
    show_y_tick_marks::Bool=true,
    show_x_tick_labels::Bool=true,
    show_y_tick_labels::Bool=true,
    x_label::String="",
    y_label::String="",
    show_x_label::Bool=false,
    show_y_label::Bool=false
)
    # Draw axis lines and tick marks at plot edges
    axis_batch = LineBatch()

    # Draw individual axis lines if enabled
    if show_bottom_axis
        # Bottom edge axis line (horizontal line at bottom of plot)
        bottom_y = plot_bounds.y
        bottom_start_x, bottom_start_y = transform_func(plot_bounds.x, bottom_y)
        bottom_end_x, bottom_end_y = transform_func(plot_bounds.x + plot_bounds.width, bottom_y)
        bottom_axis_points = [Point2f(bottom_start_x, bottom_start_y), Point2f(bottom_end_x, bottom_end_y)]
        add_line!(axis_batch, bottom_axis_points, axis_color, axis_width, SOLID)
    end

    if show_left_axis
        # Left edge axis line (vertical line at left of plot)
        left_x = plot_bounds.x
        left_start_x, left_start_y = transform_func(left_x, plot_bounds.y)
        left_end_x, left_end_y = transform_func(left_x, plot_bounds.y + plot_bounds.height)
        left_axis_points = [Point2f(left_start_x, left_start_y), Point2f(left_end_x, left_end_y)]
        add_line!(axis_batch, left_axis_points, axis_color, axis_width, SOLID)
    end

    if show_right_axis
        # Right edge axis line (vertical line at right of plot)
        right_x = plot_bounds.x + plot_bounds.width
        right_start_x, right_start_y = transform_func(right_x, plot_bounds.y)
        right_end_x, right_end_y = transform_func(right_x, plot_bounds.y + plot_bounds.height)
        right_axis_points = [Point2f(right_start_x, right_start_y), Point2f(right_end_x, right_end_y)]
        add_line!(axis_batch, right_axis_points, axis_color, axis_width, SOLID)
    end

    if show_top_axis
        # Top edge axis line (horizontal line at top of plot)
        top_y = plot_bounds.y + plot_bounds.height
        top_start_x, top_start_y = transform_func(plot_bounds.x, top_y)
        top_end_x, top_end_y = transform_func(plot_bounds.x + plot_bounds.width, top_y)
        top_axis_points = [Point2f(top_start_x, top_start_y), Point2f(top_end_x, top_end_y)]
        add_line!(axis_batch, top_axis_points, axis_color, axis_width, SOLID)
    end

    # Add tick marks for x-axis if enabled
    if show_x_tick_marks
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
    end

    # Add tick marks for y-axis if enabled
    if show_y_tick_marks
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
    end

    # Draw the axis lines and tick marks
    draw_lines(axis_batch, projection_matrix; anti_aliasing_width=anti_aliasing_width)

    # Create text style for labels
    text_style = TextStyle(size_px=label_size_px, color=label_color)

    # Draw x-axis labels along the bottom edge (outside plot area) if x-tick labels are enabled
    if show_x_tick_labels
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
    end

    # Draw y-axis labels along the left edge (outside plot area) if y-tick labels are enabled
    if show_y_tick_labels
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

    # Draw axis labels if enabled
    if show_x_label && !isempty(x_label)
        # Create Text component for x-axis label
        x_label_style = TextStyle(size_px=label_size_px + 4, color=label_color)  # Slightly larger for axis labels
        x_label_text = Text(x_label, style=x_label_style, horizontal_align=:center, vertical_align=:top)
        x_label_width, x_label_height = measure(x_label_text)

        # Position x-axis label centered below the plot, below tick labels
        bottom_edge_screen_x, bottom_edge_screen_y = transform_func(plot_bounds.x + plot_bounds.width / 2, plot_bounds.y)
        x_label_x = bottom_edge_screen_x - x_label_width / 2.0f0
        x_label_y = bottom_edge_screen_y + tick_length_px + label_offset_px + Float32(label_size_px) + label_offset_px  # Below tick labels

        # Render the x-axis label
        interpret_view(x_label_text, x_label_x, x_label_y, x_label_width, x_label_height, projection_matrix)
    end

    if show_y_label && !isempty(y_label)
        # Create Text component for y-axis label (rotated -90 degrees using Rotate component)
        y_label_style = TextStyle(size_px=label_size_px + 4, color=label_color)  # Style without rotation
        y_label_text = Rotate(Text(y_label, style=y_label_style, horizontal_align=:center, vertical_align=:middle), rotation_degrees=-90.0f0)  # Use Rotate component
        y_label_width, y_label_height = measure(y_label_text)

        # Position y-axis label centered to the left of the plot, left of tick labels
        left_edge_screen_x, left_edge_screen_y = transform_func(plot_bounds.x, plot_bounds.y + plot_bounds.height / 2)

        # For rotated text, adjust positioning
        y_label_x = left_edge_screen_x - tick_length_px - label_offset_px - Float32(label_size_px) * 3.0f0 - label_offset_px  # Left of tick labels
        y_label_y = left_edge_screen_y - y_label_height / 2.0f0  # Center vertically

        # Render the y-axis label
        interpret_view(y_label_text, y_label_x, y_label_y, y_label_width, y_label_height, projection_matrix)
    end
end
