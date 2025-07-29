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
    draw_line_batch(batch, projection_matrix)
end

# Main batched line drawing function using custom shader
function draw_line_batch(batch::LineBatch, projection_matrix::Mat4{Float32})
    if isempty(batch.points)
        return
    end

    # Try to use custom shader, fallback to CPU rendering if not available
    try
        if isdefined(@__MODULE__, :line_with_caps_prog) && line_with_caps_prog[].id != 0
            draw_lines_with_shader(batch, projection_matrix)
        else
            draw_lines_fallback(batch, projection_matrix)
        end
    catch e
        @warn "Shader rendering failed, falling back to CPU rendering: $e"
        draw_lines_fallback(batch, projection_matrix)
    end
end

# Fallback CPU-based line drawing
function draw_lines_fallback(batch::LineBatch, projection_matrix::Mat4{Float32})
    for i in 1:length(batch.segment_starts)
        start_idx = batch.segment_starts[i]
        length_seg = batch.segment_lengths[i]
        end_idx = start_idx + length_seg - 1

        line_points = batch.points[start_idx:end_idx]
        line_color = batch.colors[start_idx]  # Assume uniform color per line
        line_width = batch.widths[start_idx]  # Assume uniform width per line

        draw_line_segments_with_caps(line_points, line_color, line_width, projection_matrix)
    end
end

# High-performance line drawing using custom OpenGL shaders
function draw_lines_with_shader(batch::LineBatch, projection_matrix::Mat4{Float32})
    if isempty(batch.points)
        return
    end

    # Use the line with caps shader program
    GLA.bind(line_with_caps_prog[])

    # Set uniforms
    GLA.gluniform(line_with_caps_prog[], :projection, projection_matrix)
    GLA.gluniform(line_with_caps_prog[], :aa, 1.0f0)  # 1 pixel anti-aliasing

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

        # Generate geometry for this line segment
        seg_positions, seg_directions, seg_widths, seg_colors, seg_vertex_types =
            generate_line_attributes_with_caps(line_points, line_color, line_width)

        append!(positions, seg_positions)
        append!(directions, seg_directions)
        append!(widths, seg_widths)
        append!(colors, seg_colors)
        append!(vertex_types, seg_vertex_types)
    end

    if isempty(positions)
        GLA.unbind(line_with_caps_prog[])
        return
    end

    # Generate buffers using GLAbstraction
    buffers = GLA.generate_buffers(
        line_with_caps_prog[],
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
    GLA.unbind(line_with_caps_prog[])
end# Generate vertex data for line segments with caps
function generate_line_vertices_with_caps(points::Vector{Point2f}, color::Vec4{Float32}, width::Float32)
    vertices = Vector{Float32}()

    if length(points) < 2
        return vertices
    end

    # For each line segment, generate quad vertices
    for i in 1:(length(points)-1)
        p1 = points[i]
        p2 = points[i+1]

        # Calculate direction vector
        direction = Point2f(p2[1] - p1[1], p2[2] - p1[2])

        # Generate quad for line segment (6 vertices = 2 triangles)
        append!(vertices, generate_line_quad_vertices(p1, direction, width, color))

        # Add caps
        if i == 1
            # Start cap
            append!(vertices, generate_cap_vertices(p1, direction, width, color, true))
        end

        if i == length(points) - 1
            # End cap  
            append!(vertices, generate_cap_vertices(p2, direction, width, color, false))
        end
    end

    return vertices
end

# Generate vertex attributes as separate arrays for GLAbstraction
function generate_line_attributes_with_caps(points::Vector{Point2f}, color::Vec4{Float32}, width::Float32)
    positions = Vector{Point2f}()
    directions = Vector{Point2f}()
    widths = Vector{Float32}()
    colors = Vector{Vec4{Float32}}()
    vertex_types = Vector{Float32}()

    if length(points) < 2
        return positions, directions, widths, colors, vertex_types
    end

    # For each line segment, generate quad vertices
    for i in 1:(length(points)-1)
        p1 = points[i]
        p2 = points[i+1]

        # Calculate direction vector
        direction = Point2f(p2[1] - p1[1], p2[2] - p1[2])

        # Generate quad for line segment
        seg_positions, seg_directions, seg_widths, seg_colors, seg_vertex_types =
            generate_line_quad_attributes(p1, direction, width, color)

        append!(positions, seg_positions)
        append!(directions, seg_directions)
        append!(widths, seg_widths)
        append!(colors, seg_colors)
        append!(vertex_types, seg_vertex_types)

        # Add caps
        if i == 1
            # Start cap
            cap_positions, cap_directions, cap_widths, cap_colors, cap_vertex_types =
                generate_cap_attributes(p1, direction, width, color, true)
            append!(positions, cap_positions)
            append!(directions, cap_directions)
            append!(widths, cap_widths)
            append!(colors, cap_colors)
            append!(vertex_types, cap_vertex_types)
        end

        if i == length(points) - 1
            # End cap  
            cap_positions, cap_directions, cap_widths, cap_colors, cap_vertex_types =
                generate_cap_attributes(p2, direction, width, color, false)
            append!(positions, cap_positions)
            append!(directions, cap_directions)
            append!(widths, cap_widths)
            append!(colors, cap_colors)
            append!(vertex_types, cap_vertex_types)
        end
    end

    return positions, directions, widths, colors, vertex_types
end

# Generate quad vertices for a single line segment
function generate_line_quad_vertices(start_pos::Point2f, direction::Point2f, width::Float32, color::Vec4{Float32})
    vertices = Vector{Float32}()

    # Each vertex: position(2) + direction(2) + width(1) + color(4) + vertex_type(1) = 10 floats
    # Generate 6 vertices for 2 triangles (quad)

    vertex_types = [0.0f0, 1.0f0, 2.0f0, 3.0f0]  # 4 vertices of the quad

    quad_vertices = Vector{Float32}()
    for (i, vertex_type) in enumerate(vertex_types)
        # Position
        push!(quad_vertices, start_pos[1])
        push!(quad_vertices, start_pos[2])

        # Direction
        push!(quad_vertices, direction[1])
        push!(quad_vertices, direction[2])

        # Width
        push!(quad_vertices, width)

        # Color
        push!(quad_vertices, color[1])
        push!(quad_vertices, color[2])
        push!(quad_vertices, color[3])
        push!(quad_vertices, color[4])

        # Vertex type
        push!(quad_vertices, vertex_type)
    end

    # Convert to triangles (0,1,2) and (0,2,3)
    # First triangle: 0, 1, 2
    append!(vertices, quad_vertices[1:10])      # vertex 0
    append!(vertices, quad_vertices[11:20])     # vertex 1  
    append!(vertices, quad_vertices[21:30])     # vertex 2

    # Second triangle: 0, 2, 3
    append!(vertices, quad_vertices[1:10])      # vertex 0
    append!(vertices, quad_vertices[21:30])     # vertex 2
    append!(vertices, quad_vertices[31:40])     # vertex 3

    return vertices
end

# Generate quad attributes as separate arrays
function generate_line_quad_attributes(start_pos::Point2f, direction::Point2f, width::Float32, color::Vec4{Float32})
    positions = Vector{Point2f}()
    directions = Vector{Point2f}()
    widths = Vector{Float32}()
    colors = Vector{Vec4{Float32}}()
    vertex_types = Vector{Float32}()

    vertex_type_values = [0.0f0, 1.0f0, 2.0f0, 3.0f0]  # 4 vertices of the quad

    # Generate quad vertices
    for vertex_type in vertex_type_values
        push!(positions, start_pos)
        push!(directions, direction)
        push!(widths, width)
        push!(colors, color)
        push!(vertex_types, vertex_type)
    end

    # Convert to triangles (0,1,2) and (0,2,3)
    tri_positions = Vector{Point2f}()
    tri_directions = Vector{Point2f}()
    tri_widths = Vector{Float32}()
    tri_colors = Vector{Vec4{Float32}}()
    tri_vertex_types = Vector{Float32}()

    # First triangle: 0, 1, 2
    push!(tri_positions, positions[1], positions[2], positions[3])
    push!(tri_directions, directions[1], directions[2], directions[3])
    push!(tri_widths, widths[1], widths[2], widths[3])
    push!(tri_colors, colors[1], colors[2], colors[3])
    push!(tri_vertex_types, vertex_types[1], vertex_types[2], vertex_types[3])

    # Second triangle: 0, 2, 3
    push!(tri_positions, positions[1], positions[3], positions[4])
    push!(tri_directions, directions[1], directions[3], directions[4])
    push!(tri_widths, widths[1], widths[3], widths[4])
    push!(tri_colors, colors[1], colors[3], colors[4])
    push!(tri_vertex_types, vertex_types[1], vertex_types[3], vertex_types[4])

    return tri_positions, tri_directions, tri_widths, tri_colors, tri_vertex_types
end

# Generate vertices for round caps
function generate_cap_vertices(center::Point2f, direction::Point2f, width::Float32, color::Vec4{Float32}, is_start::Bool)
    vertices = Vector{Float32}()

    # Generate triangle fan for circular cap
    num_segments = 8  # Adjust for quality vs performance

    # For caps, we use vertex_type 4-7 for start cap, 8-11 for end cap
    base_vertex_type = is_start ? 4.0f0 : 8.0f0

    for i in 0:(num_segments-1)
        # Triangle: center, point i, point i+1

        # Center vertex
        push!(vertices, center[1])
        push!(vertices, center[2])
        push!(vertices, direction[1])
        push!(vertices, direction[2])
        push!(vertices, width)
        push!(vertices, color[1])
        push!(vertices, color[2])
        push!(vertices, color[3])
        push!(vertices, color[4])
        push!(vertices, base_vertex_type)  # vertex_type

        # First edge point
        angle1 = 2.0f0 * π * i / num_segments
        radius = width * 0.5f0
        x1 = center[1] + radius * cos(angle1)
        y1 = center[2] + radius * sin(angle1)

        push!(vertices, x1)
        push!(vertices, y1)
        push!(vertices, direction[1])
        push!(vertices, direction[2])
        push!(vertices, width)
        push!(vertices, color[1])
        push!(vertices, color[2])
        push!(vertices, color[3])
        push!(vertices, color[4])
        push!(vertices, base_vertex_type + 1.0f0)  # vertex_type

        # Second edge point
        angle2 = 2.0f0 * π * (i + 1) / num_segments
        x2 = center[1] + radius * cos(angle2)
        y2 = center[2] + radius * sin(angle2)

        push!(vertices, x2)
        push!(vertices, y2)
        push!(vertices, direction[1])
        push!(vertices, direction[2])
        push!(vertices, width)
        push!(vertices, color[1])
        push!(vertices, color[2])
        push!(vertices, color[3])
        push!(vertices, color[4])
        push!(vertices, base_vertex_type + 2.0f0)  # vertex_type
    end

    return vertices
end

# Generate cap attributes as separate arrays
function generate_cap_attributes(center::Point2f, direction::Point2f, width::Float32, color::Vec4{Float32}, is_start::Bool)
    positions = Vector{Point2f}()
    directions = Vector{Point2f}()
    widths = Vector{Float32}()
    colors = Vector{Vec4{Float32}}()
    vertex_types = Vector{Float32}()

    # Generate triangle fan for circular cap
    num_segments = 8  # Adjust for quality vs performance

    # For caps, we use vertex_type 4-7 for start cap, 8-11 for end cap
    base_vertex_type = is_start ? 4.0f0 : 8.0f0

    for i in 0:(num_segments-1)
        # Triangle: center, point i, point i+1

        # Center vertex
        push!(positions, center)
        push!(directions, direction)
        push!(widths, width)
        push!(colors, color)
        push!(vertex_types, base_vertex_type)

        # First edge point
        angle1 = 2.0f0 * π * i / num_segments
        radius = width * 0.5f0
        x1 = center[1] + radius * cos(angle1)
        y1 = center[2] + radius * sin(angle1)

        push!(positions, Point2f(x1, y1))
        push!(directions, direction)
        push!(widths, width)
        push!(colors, color)
        push!(vertex_types, base_vertex_type + 1.0f0)

        # Second edge point
        angle2 = 2.0f0 * π * (i + 1) / num_segments
        x2 = center[1] + radius * cos(angle2)
        y2 = center[2] + radius * sin(angle2)

        push!(positions, Point2f(x2, y2))
        push!(directions, direction)
        push!(widths, width)
        push!(colors, color)
        push!(vertex_types, base_vertex_type + 2.0f0)
    end

    return positions, directions, widths, colors, vertex_types
end

# Draw scatter points using custom point shader
function draw_points_with_shader(points::Vector{Point2f}, colors::Vector{Vec4{Float32}}, sizes::Vector{Float32}, projection_matrix::Mat4{Float32})
    if isempty(points)
        return
    end

    # Use the point shader program
    GLA.bind(point_prog[])

    # Set uniforms
    GLA.gluniform(point_prog[], :projection, projection_matrix)
    GLA.gluniform(point_prog[], :aa, 1.0f0)  # 1 pixel anti-aliasing

    # Generate vertex data for all points
    vertices = Vector{Float32}()

    for i in 1:length(points)
        point = points[i]
        color = colors[min(i, length(colors))]  # Reuse last color if not enough colors
        size = sizes[min(i, length(sizes))]     # Reuse last size if not enough sizes

        # Generate quad for this point (6 vertices = 2 triangles)
        append!(vertices, generate_point_quad_vertices(point, size, color))
    end

    if isempty(vertices)
        GLA.unbind(point_prog[])
        return
    end

    # Create and bind vertex buffer
    vbo = Ref{GLuint}()
    GLA.glGenBuffers(1, vbo)
    GLA.glBindBuffer(GLA.GL_ARRAY_BUFFER, vbo[])
    GLA.glBufferData(GLA.GL_ARRAY_BUFFER, sizeof(vertices), vertices, GLA.GL_STATIC_DRAW)

    # Create and bind vertex array object
    vao = Ref{GLuint}()
    GLA.glGenVertexArrays(1, vao)
    GLA.glBindVertexArray(vao[])

    # Set up vertex attributes
    stride = 7 * sizeof(Float32)  # position(2) + size(1) + color(4)

    # Position (location 0)
    GLA.glVertexAttribPointer(0, 2, GLA.GL_FLOAT, false, stride, 0)
    GLA.glEnableVertexAttribArray(0)

    # Size (location 1)
    GLA.glVertexAttribPointer(1, 1, GLA.GL_FLOAT, false, stride, 2 * sizeof(Float32))
    GLA.glEnableVertexAttribArray(1)

    # Color (location 2)
    GLA.glVertexAttribPointer(2, 4, GLA.GL_FLOAT, false, stride, 3 * sizeof(Float32))
    GLA.glEnableVertexAttribArray(2)

    # UV coordinates (location 3) - handled in vertex generation

    # Draw the vertices
    num_vertices = div(length(vertices), 7)
    GLA.glDrawArrays(GLA.GL_TRIANGLES, 0, num_vertices)

    # Cleanup
    GLA.glBindVertexArray(0)
    GLA.glBindBuffer(GLA.GL_ARRAY_BUFFER, 0)
    GLA.glDeleteBuffers(1, vbo)
    GLA.glDeleteVertexArrays(1, vao)

    # Unbind shader program
    GLA.unbind(point_prog[])
end# Generate quad vertices for a point
function generate_point_quad_vertices(center::Point2f, size::Float32, color::Vec4{Float32})
    vertices = Vector{Float32}()

    # Each vertex: position(2) + size(1) + color(4) = 7 floats
    # Generate 6 vertices for 2 triangles (quad)

    # UV coordinates for quad corners
    uvs = [Point2f(0, 0), Point2f(1, 0), Point2f(1, 1), Point2f(0, 1)]

    # Generate quad vertices
    quad_vertices = Vector{Float32}()
    for uv in uvs
        push!(quad_vertices, center[1])
        push!(quad_vertices, center[2])
        push!(quad_vertices, size)
        push!(quad_vertices, color[1])
        push!(quad_vertices, color[2])
        push!(quad_vertices, color[3])
        push!(quad_vertices, color[4])
    end

    # Convert to triangles (0,1,2) and (0,2,3)
    # First triangle: 0, 1, 2
    append!(vertices, quad_vertices[1:7])      # vertex 0
    append!(vertices, quad_vertices[8:14])     # vertex 1  
    append!(vertices, quad_vertices[15:21])    # vertex 2

    # Second triangle: 0, 2, 3
    append!(vertices, quad_vertices[1:7])      # vertex 0
    append!(vertices, quad_vertices[15:21])    # vertex 2
    append!(vertices, quad_vertices[22:28])    # vertex 3

    return vertices
end

# Draw line segments with round end caps for smooth joints
function draw_line_segments_with_caps(
    points::Vector{Point2f},
    color::Vec4{Float32},
    width::Float32,
    projection_matrix::Mat4{Float32}
)
    if length(points) < 2
        return
    end

    half_width = width * 0.5f0

    # Draw each segment
    for i in 1:(length(points)-1)
        p1 = points[i]
        p2 = points[i+1]

        # Draw the main line segment
        draw_thick_line_segment(p1, p2, width, color, projection_matrix)

        # Draw round caps at joints (except for first and last points)
        if i == 1
            # Start cap
            draw_round_cap(p1, half_width, color, projection_matrix)
        end

        if i == length(points) - 1
            # End cap
            draw_round_cap(p2, half_width, color, projection_matrix)
        else
            # Joint cap (where two segments meet)
            draw_round_cap(p2, half_width, color, projection_matrix)
        end
    end
end

# Draw a round cap (circle) at a point
function draw_round_cap(center::Point2f, radius::Float32, color::Vec4{Float32}, projection_matrix::Mat4{Float32})
    # Create circle vertices
    num_segments = 16  # Adjust for quality vs performance
    vertices = Vector{Point2f}()
    sizehint!(vertices, num_segments + 2)

    # Center point
    push!(vertices, center)

    # Circle points
    for i in 0:num_segments
        angle = 2.0f0 * π * i / num_segments
        x = center[1] + radius * cos(angle)
        y = center[2] + radius * sin(angle)
        push!(vertices, Point2f(x, y))
    end

    # Draw as triangle fan
    draw_triangle_fan(vertices, color, projection_matrix)
end

# Helper function for triangle fan drawing (fallback implementation)
function draw_triangle_fan(vertices::Vector{Point2f}, color::Vec4{Float32}, projection_matrix::Mat4{Float32})
    if length(vertices) < 3
        return
    end

    # Convert triangle fan to individual triangles
    center = vertices[1]
    triangles = Vector{Point2f}()

    for i in 2:(length(vertices)-1)
        # Each triangle: center, vertex i, vertex i+1
        push!(triangles, center)
        push!(triangles, vertices[i])
        push!(triangles, vertices[i+1])
    end

    # Draw triangles using existing drawing system
    # This is a simplified fallback - you may need to implement draw_triangles
    # or use your existing drawing functions
    for i in 1:3:length(triangles)-2
        triangle_verts = [triangles[i], triangles[i+1], triangles[i+2]]
        # TODO: Use your existing triangle drawing function here
        # draw_triangle(triangle_verts, color, projection_matrix)
    end
end# Helper function for thick line segments (draw as rectangle)

function draw_thick_line_segment(p1::Point2f, p2::Point2f, width::Float32, color::Vec4{Float32}, projection_matrix::Mat4{Float32})
    # Calculate direction vector and perpendicular
    dx = p2[1] - p1[1]
    dy = p2[2] - p1[2]
    length = sqrt(dx^2 + dy^2)

    if length < 1e-6  # Avoid division by zero
        return
    end

    # Normalize direction vector
    dir_x = dx / length
    dir_y = dy / length

    # Perpendicular vector (rotated 90 degrees)
    perp_x = -dir_y
    perp_y = dir_x

    # Half width offset
    half_width = width * 0.5f0
    offset_x = perp_x * half_width
    offset_y = perp_y * half_width

    # Create rectangle vertices for the thick line
    vertices = [
        Point2f(p1[1] + offset_x, p1[2] + offset_y),  # Top-left
        Point2f(p1[1] - offset_x, p1[2] - offset_y),  # Bottom-left
        Point2f(p2[1] - offset_x, p2[2] - offset_y),  # Bottom-right
        Point2f(p2[1] + offset_x, p2[2] + offset_y)   # Top-right
    ]

    # Draw as filled rectangle
    draw_rectangle(vertices, color, projection_matrix)
end
