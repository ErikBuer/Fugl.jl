"""
Vertical line separator that fills available height
"""
struct VerticalLineView <: SizedView
    style::SeparatorStyle
    end_length::Float32  # Extra length on each side beyond assigned height (can be negative for undersizing)

    function VerticalLineView(style::SeparatorStyle=SeparatorStyle(), end_length::Float32=0.0f0)
        return new(style, end_length)
    end
end

"""
Vertical line separator that fills available height.
"""
VerticalLine(; style::SeparatorStyle=SeparatorStyle(), end_length::Float32=0.0f0) = VerticalLineView(style, end_length)

"""
Convenience constructor for vertical line
"""
VLine(; style::SeparatorStyle=SeparatorStyle(), end_length::Float32=0.0f0) = VerticalLineView(style, end_length)

function measure(view::VerticalLineView)::Tuple{Float32,Float32}
    # Width: line width, Height: fill available (Inf32)
    return (view.style.line_width, Inf32)  # Width and height
end

function apply_layout(view::VerticalLineView, x::Float32, y::Float32, width::Float32, height::Float32)
    # Use the assigned position and size, but extend height by end_length on both sides
    actual_height = height + 2 * view.end_length
    actual_y = y - view.end_length  # Move down by end_length to center the extension
    return (x, actual_y, width, actual_height)
end

function interpret_view(view::VerticalLineView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    # Draw a vertical line rectangle
    x, actual_y, width, actual_height = apply_layout(view, x, y, width, height)

    # Create positions for a rectangle representing the line
    positions = Point2f[
        Point2f(x, actual_y),                                         # Bottom-left
        Point2f(x + view.style.line_width, actual_y),                 # Bottom-right
        Point2f(x + view.style.line_width, actual_y + actual_height), # Top-right
        Point2f(x, actual_y + actual_height)                          # Top-left
    ]

    # All vertices have the same color
    colors = Vec4{Float32}[view.style.color for _ in 1:4]

    # Define triangles (two triangles form the rectangle)
    elements = NgonFace{3,UInt32}[
        (0, 1, 2),  # First triangle: bottom-left, bottom-right, top-right
        (2, 3, 0)   # Second triangle: top-right, top-left, bottom-left
    ]

    # Generate buffers
    buffers = GLA.generate_buffers(prog[], position=positions, color=colors)
    vao = GLA.VertexArray(buffers, elements)

    # Render
    GLA.bind(prog[])
    GLA.gluniform(prog[], :use_texture, false)
    GLA.gluniform(prog[], :projection, projection_matrix)
    GLA.bind(vao)
    GLA.draw(vao)
    GLA.unbind(vao)
    GLA.unbind(prog[])
end

function preferred_width(view::VerticalLineView)::Bool
    return true
end