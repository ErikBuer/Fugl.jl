# Helper function to draw line plot
function draw_line_plot(
    x_data::Vector{Float32},
    y_data::Vector{Float32},
    transform_func::Function,
    color::Vec4{Float32},
    width::Float32,
    projection_matrix::Mat4{Float32}
)
    if length(x_data) != length(y_data) || length(x_data) < 2
        return  # Need at least 2 points and matching arrays
    end

    # Transform all data points to screen coordinates
    screen_points = Vector{Point2f}()
    sizehint!(screen_points, length(x_data))

    for i in 1:length(x_data)
        screen_x, screen_y = transform_func(x_data[i], y_data[i])
        push!(screen_points, Point2f(screen_x, screen_y))
    end

    # Draw connected line segments
    for i in 1:(length(screen_points)-1)
        p1 = screen_points[i]
        p2 = screen_points[i+1]

        # Create line segment vertices
        line_vertices = [p1, p2]

        # Draw the line segment
        # Note: You might need to implement draw_line_segment if it doesn't exist
        # For now, using a thick line approach with rectangles if width > 1
        if width <= 1.0f0
            # Thin line - could use GL_LINES if available
            draw_line_segment(line_vertices, color, projection_matrix)
        else
            # Thick line - draw as a rectangle
            draw_thick_line_segment(p1, p2, width, color, projection_matrix)
        end
    end
end

# Helper function for thin line segments
function draw_line_segment(vertices::Vector{Point2f}, color::Vec4{Float32}, projection_matrix::Mat4{Float32})
    # This would use OpenGL GL_LINES primitive
    # For now, placeholder - you'll need to implement based on your OpenGL setup
    println("Drawing thin line segment from $(vertices[1]) to $(vertices[2])")
end

# Helper function for thick line segments (draw as rectangle)
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
