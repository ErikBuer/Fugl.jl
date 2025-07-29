# Efficient line plotting using custom shaders and batching
struct LineBatch
    points::Vector{Point2f}      # All line points
    colors::Vector{Vec4{Float32}} # Color per point (for gradients)
    widths::Vector{Float32}      # Width per point (for variable thickness)
    segment_starts::Vector{Int32} # Start indices for each line segment
    segment_lengths::Vector{Int32} # Length of each line segment
end

function LineBatch()
    return LineBatch(
        Point2f[],
        Vec4{Float32}[],
        Float32[],
        Int32[],
        Int32[]
    )
end

# Add a complete line (series of connected points) to the batch
function add_line!(batch::LineBatch, points::Vector{Point2f}, color::Vec4{Float32}, width::Float32)
    if length(points) < 2
        return  # Need at least 2 points for a line
    end

    start_idx = length(batch.points) + 1

    # Add all points
    append!(batch.points, points)

    # Add color and width for each point
    for _ in 1:length(points)
        push!(batch.colors, color)
        push!(batch.widths, width)
    end

    # Record this line segment
    push!(batch.segment_starts, Int32(start_idx))
    push!(batch.segment_lengths, Int32(length(points)))
end

# Optimized line drawing using custom shader
function draw_line_plot(
    x_data::Vector{Float32},
    y_data::Vector{Float32},
    transform_func::Function,
    color::Vec4{Float32},
    width::Float32,
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
    add_line!(batch, screen_points, color, width)

    # Draw the batch
    draw_lines_simple(batch, projection_matrix)
end

# Simplified line drawing using the simple shader
function draw_lines_simple(batch::LineBatch, projection_matrix::Mat4{Float32})
    if isempty(batch.points)
        return
    end

    # Use the simple line shader program
    GLA.bind(simple_line_prog[])

    # Set uniforms
    GLA.gluniform(simple_line_prog[], :projection, projection_matrix)

    # Generate vertex data for all line segments
    positions = Vector{Point2f}()
    directions = Vector{Point2f}()
    widths = Vector{Float32}()
    colors = Vector{Vec4{Float32}}()
    vertex_types = Vector{Float32}()

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

        # Generate simple line geometry (just quads, no caps or joints)
        seg_positions, seg_directions, seg_widths, seg_colors, seg_vertex_types =
            generate_simple_line_geometry(line_points, line_color, line_width)

        append!(positions, seg_positions)
        append!(directions, seg_directions)
        append!(widths, seg_widths)
        append!(colors, seg_colors)
        append!(vertex_types, seg_vertex_types)
    end

    if isempty(positions)
        GLA.unbind(simple_line_prog[])
        return
    end

    # Generate buffers using GLAbstraction
    buffers = GLA.generate_buffers(
        simple_line_prog[],
        position=positions,
        direction=directions,
        width=widths,
        color=colors,
        vertex_type=vertex_types
    )

    # Create VAO and draw
    vao = GLA.VertexArray(buffers)

    GLA.bind(vao)
    GLA.draw(vao)
    GLA.unbind(vao)

    # Unbind shader program
    GLA.unbind(simple_line_prog[])
end

# Generate simple line geometry - just line segment quads
function generate_simple_line_geometry(points::Vector{Point2f}, color::Vec4{Float32}, width::Float32)
    positions = Vector{Point2f}()
    directions = Vector{Point2f}()
    widths = Vector{Float32}()
    colors = Vector{Vec4{Float32}}()
    vertex_types = Vector{Float32}()

    if length(points) < 2
        return positions, directions, widths, colors, vertex_types
    end

    # For each line segment, generate a quad
    for i in 1:(length(points)-1)
        start_point = points[i]
        end_point = points[i+1]

        # Calculate direction vector
        direction_vec = Point2f(end_point[1] - start_point[1], end_point[2] - start_point[2])

        # Generate quad vertices (2 triangles = 6 vertices)
        # Triangle 1: bottom-left, bottom-right, top-left
        push!(positions, start_point, start_point, start_point)
        push!(directions, direction_vec, direction_vec, direction_vec)
        push!(widths, width, width, width)
        push!(colors, color, color, color)
        push!(vertex_types, 0.0f0, 1.0f0, 2.0f0)  # bottom-left, bottom-right, top-left

        # Triangle 2: bottom-right, top-right, top-left
        push!(positions, start_point, start_point, start_point)
        push!(directions, direction_vec, direction_vec, direction_vec)
        push!(widths, width, width, width)
        push!(colors, color, color, color)
        push!(vertex_types, 1.0f0, 3.0f0, 2.0f0)  # bottom-right, top-right, top-left
    end

    return positions, directions, widths, colors, vertex_types
end
