include("separator_style.jl")

"""
Horizontal line separator that fills available width
"""
struct HorizontalLineView <: SizedView
    style::SeparatorStyle
    end_length::Float32  # Extra length on each side beyond assigned width (can be negative for undersizing)

    function HorizontalLineView(style::SeparatorStyle=SeparatorStyle(), end_length::Float32=0.0f0)
        return new(style, end_length)
    end
end

HorizontalLine(style::SeparatorStyle=SeparatorStyle(), end_length::Float32=0.0f0) = HorizontalLineView(style, end_length)
HorizontalLine(; style::SeparatorStyle=SeparatorStyle(), end_length::Float32=0.0f0) = HorizontalLineView(style, end_length)

"""
Convenience constructor for horizontal line
"""
HLine(style::SeparatorStyle=SeparatorStyle(), end_length::Float32=0.0f0) = HorizontalLineView(style, end_length)
HLine(; style::SeparatorStyle=SeparatorStyle(), end_length::Float32=0.0f0) = HorizontalLineView(style, end_length)

function measure(view::HorizontalLineView)::Tuple{Float32,Float32}
    # Width: fill available (Inf32), Height: line width
    return (Inf32, view.style.line_width)  # Width and height
end

function apply_layout(view::HorizontalLineView, x::Float32, y::Float32, width::Float32, height::Float32)
    # Use the assigned position and size, but extend width by end_length on both sides
    actual_width = width + 2 * view.end_length
    actual_x = x - view.end_length  # Move left by end_length to center the extension
    return (actual_x, y, actual_width, height)
end

function interpret_view(view::HorizontalLineView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    # Draw a horizontal line rectangle
    actual_x, y, actual_width, height = apply_layout(view, x, y, width, height)

    # Create positions for a rectangle representing the line
    positions = Point2f[
        Point2f(actual_x, y),                                         # Bottom-left
        Point2f(actual_x + actual_width, y),                          # Bottom-right
        Point2f(actual_x + actual_width, y + view.style.line_width),  # Top-right
        Point2f(actual_x, y + view.style.line_width)                  # Top-left
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

function preferred_height(view::HorizontalLineView)::Bool
    return true
end