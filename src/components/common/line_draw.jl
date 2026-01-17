"""
General-purpose line drawing functions for UI components like checkboxes.
Based on the plot line drawing functionality but simplified for common UI use.
"""

"""
Simple struct for storing lines to be drawn.
"""
struct SimpleLine
    points::Vector{Point2f}
    color::Vec4{Float32}
    width::Float32
    line_style::LinePattern
end

"""
    calculate_line_progress(points::Vector{Point2f})

Calculate cumulative distance along the line for pattern calculations.
"""
function calculate_line_progress(points::Vector{Point2f})
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
    generate_line_geometry(points::Vector{Point2f}, color::Vec4{Float32}, width::Float32, line_style::LinePattern)

Generate geometry for a single line using triangles.
Returns arrays for positions, directions, widths, colors, vertex_types, line_styles, and line_progresses.
"""
function generate_line_geometry(points::Vector{Point2f}, color::Vec4{Float32}, width::Float32, line_style::LinePattern, line_cap::LineCap=ROUND_CAP)
    positions = Vector{Point2f}()
    directions = Vector{Point2f}()
    widths = Vector{Float32}()
    colors = Vector{Vec4{Float32}}()
    vertex_types = Vector{Float32}()
    line_styles = Vector{Float32}()
    line_progresses_out = Vector{Float32}()
    line_cap_types = Vector{Float32}()

    if length(points) < 2
        return positions, directions, widths, colors, vertex_types, line_styles, line_progresses_out, line_cap_types
    end

    # Calculate progress along the line
    line_progresses = calculate_line_progress(points)

    # Convert enum to Float32 for shader compatibility
    line_style_f32 = Float32(line_style)
    line_cap_f32 = Float32(line_cap)

    # Pre-allocate for efficiency (2 triangles = 6 vertices per segment)
    num_segments = length(points) - 1
    sizehint!(positions, num_segments * 6)
    sizehint!(directions, num_segments * 6)
    sizehint!(widths, num_segments * 6)
    sizehint!(colors, num_segments * 6)
    sizehint!(vertex_types, num_segments * 6)
    sizehint!(line_styles, num_segments * 6)
    sizehint!(line_progresses_out, num_segments * 6)
    sizehint!(line_cap_types, num_segments * 6)

    # Generate geometry for each segment 
    for i in 1:(length(points)-1)
        start_point = points[i]
        end_point = points[i+1]
        start_progress = line_progresses[i]
        end_progress = line_progresses[i+1]

        # Calculate direction vector for current segment
        direction_vec = Point2f(end_point[1] - start_point[1], end_point[2] - start_point[2])

        # Generate 2 triangles (6 vertices) for this segment
        # Triangle 1: bottom-left, bottom-right, top-left
        append!(positions, [start_point, start_point, start_point])
        append!(directions, [direction_vec, direction_vec, direction_vec])
        append!(widths, [width, width, width])
        append!(colors, [color, color, color])
        append!(vertex_types, [0.0f0, 1.0f0, 2.0f0])  # bottom-left, bottom-right, top-left
        append!(line_styles, [line_style_f32, line_style_f32, line_style_f32])
        append!(line_progresses_out, [start_progress, end_progress, start_progress])
        append!(line_cap_types, [line_cap_f32, line_cap_f32, line_cap_f32])

        # Triangle 2: bottom-right, top-right, top-left
        append!(positions, [start_point, start_point, start_point])
        append!(directions, [direction_vec, direction_vec, direction_vec])
        append!(widths, [width, width, width])
        append!(colors, [color, color, color])
        append!(vertex_types, [1.0f0, 3.0f0, 2.0f0])  # bottom-right, top-right, top-left
        append!(line_styles, [line_style_f32, line_style_f32, line_style_f32])
        append!(line_progresses_out, [end_progress, end_progress, start_progress])
        append!(line_cap_types, [line_cap_f32, line_cap_f32, line_cap_f32])
    end

    return positions, directions, widths, colors, vertex_types, line_styles, line_progresses_out, line_cap_types
end

"""
    draw_line(points::Vector{Point2f}, color::Vec4{Float32}, width::Float32, line_style::LinePattern, projection_matrix::Mat4{Float32}; anti_aliasing_width::Float32=1.5f0)

Draw a single line with the specified properties.
"""
function draw_line(
    points::Vector{Point2f},
    color::Vec4{Float32},
    width::Float32,
    line_style::LinePattern,
    projection_matrix::Mat4{Float32};
    line_cap::LineCap=ROUND_CAP,
    anti_aliasing_width::Float32=1.5f0
)
    if length(points) < 2
        return
    end

    # Generate geometry
    positions, directions, widths, colors, vertex_types, line_styles, line_progresses, line_cap_types =
        generate_line_geometry(points, color, width, line_style, line_cap)

    if isempty(positions)
        return
    end

    # Use the line shader program
    GLA.bind(line_prog[])

    # Set uniforms
    GLA.gluniform(line_prog[], :projection, projection_matrix)
    GLA.gluniform(line_prog[], :anti_aliasing_width, anti_aliasing_width)

    # Generate buffers using GLAbstraction
    buffers = GLA.generate_buffers(
        line_prog[],
        position=positions,
        direction=directions,
        width=widths,
        color=colors,
        vertex_type=vertex_types,
        line_style=line_styles,
        line_progress=line_progresses,
        line_cap_type=line_cap_types
    )

    # Create VAO and draw
    vao = GLA.VertexArray(buffers)

    GLA.bind(vao)
    GLA.draw(vao)
    GLA.unbind(vao)

    # Unbind shader program
    GLA.unbind(line_prog[])
end

"""
    draw_lines(lines::Vector{SimpleLine}, projection_matrix::Mat4{Float32}; anti_aliasing_width::Float32=1.5f0)

Draw multiple lines efficiently in a single batch.
"""
function draw_lines(
    lines::Vector{SimpleLine},
    projection_matrix::Mat4{Float32};
    anti_aliasing_width::Float32=1.5f0
)
    if isempty(lines)
        return
    end

    # Collect all geometry data
    all_positions = Vector{Point2f}()
    all_directions = Vector{Point2f}()
    all_widths = Vector{Float32}()
    all_colors = Vector{Vec4{Float32}}()
    all_vertex_types = Vector{Float32}()
    all_line_styles = Vector{Float32}()
    all_line_progresses = Vector{Float32}()
    all_line_cap_types = Vector{Float32}()

    # Process each line
    for line in lines
        if length(line.points) >= 2
            positions, directions, widths, colors, vertex_types, line_styles, line_progresses, line_cap_types =
                generate_line_geometry(line.points, line.color, line.width, line.line_style)

            append!(all_positions, positions)
            append!(all_directions, directions)
            append!(all_widths, widths)
            append!(all_colors, colors)
            append!(all_vertex_types, vertex_types)
            append!(all_line_styles, line_styles)
            append!(all_line_progresses, line_progresses)
            append!(all_line_cap_types, line_cap_types)
        end
    end

    if isempty(all_positions)
        return
    end

    # Use the line shader program
    GLA.bind(line_prog[])

    # Set uniforms
    GLA.gluniform(line_prog[], :projection, projection_matrix)
    GLA.gluniform(line_prog[], :anti_aliasing_width, anti_aliasing_width)

    # Generate buffers using GLAbstraction
    buffers = GLA.generate_buffers(
        line_prog[],
        position=all_positions,
        direction=all_directions,
        width=all_widths,
        color=all_colors,
        vertex_type=all_vertex_types,
        line_style=all_line_styles,
        line_progress=all_line_progresses,
        line_cap_type=all_line_cap_types
    )

    # Create VAO and draw
    vao = GLA.VertexArray(buffers)

    GLA.bind(vao)
    GLA.draw(vao)
    GLA.unbind(vao)

    # Unbind shader program
    GLA.unbind(line_prog[])
end

"""
    draw_simple_line(start_point::Point2f, end_point::Point2f, color::Vec4{Float32}, width::Float32, projection_matrix::Mat4{Float32}; line_style::LinePattern=SOLID, anti_aliasing_width::Float32=1.5f0)

Convenience function to draw a simple line between two points.
"""
function draw_simple_line(
    start_point::Point2f,
    end_point::Point2f,
    color::Vec4{Float32},
    width::Float32,
    projection_matrix::Mat4{Float32};
    line_style::LinePattern=SOLID,
    line_cap::LineCap=ROUND_CAP,
    anti_aliasing_width::Float32=1.5f0
)
    points = [start_point, end_point]
    draw_line(points, color, width, line_style, projection_matrix; line_cap=line_cap, anti_aliasing_width=anti_aliasing_width)
end
