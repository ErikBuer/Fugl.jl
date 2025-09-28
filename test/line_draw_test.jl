using Fugl
using Fugl: Point2f, Text
using StaticArraysCore

# Custom container that draws lines
struct LineDrawContainer <: AbstractView
    lines::Vector{SimpleLine}
    background_color::Vec4{Float32}
end

function Fugl.interpret_view(view::LineDrawContainer, x::Float32, y::Float32, available_width::Float32, available_height::Float32, projection_matrix::StaticArraysCore.SMatrix{4,4,Float32,16})
    # Draw background
    vertices = [
        Point2f(x, y),                              # Bottom-left
        Point2f(x + available_width, y),            # Bottom-right
        Point2f(x + available_width, y + available_height), # Top-right
        Point2f(x, y + available_height)            # Top-left
    ]
    Fugl.draw_rounded_rectangle(
        vertices,
        available_width,
        available_height,
        view.background_color,
        Vec4{Float32}(0, 0, 0, 0), # No border
        0.0f0,                     # Border width
        0.0f0,                     # Corner radius  
        projection_matrix,
        1.5f0                      # Anti-aliasing width
    )

    # Draw all lines
    draw_lines(view.lines, projection_matrix)

    return available_width, available_height
end

function Fugl.measure(view::LineDrawContainer)::Tuple{Float32,Float32}
    return (400.0f0, 300.0f0)
end

function MyApp()

    # Create some test lines
    lines = [
        # Horizontal line
        SimpleLine([Point2f(50, 50), Point2f(200, 50)], Vec4{Float32}(1.0, 0.0, 0.0, 1.0), 2.0f0, SOLID),
        # Vertical line  
        SimpleLine([Point2f(50, 50), Point2f(50, 150)], Vec4{Float32}(0.0, 1.0, 0.0, 1.0), 2.0f0, SOLID),
        # Diagonal line
        SimpleLine([Point2f(50, 50), Point2f(150, 150)], Vec4{Float32}(0.0, 0.0, 1.0, 1.0), 3.0f0, SOLID),
        # Dashed line
        SimpleLine([Point2f(220, 50), Point2f(350, 100)], Vec4{Float32}(1.0, 0.5, 0.0, 1.0), 2.0f0, DASH),
        # Dotted line
        SimpleLine([Point2f(220, 120), Point2f(350, 170)], Vec4{Float32}(0.5, 0.0, 1.0, 1.0), 2.0f0, DOT),
        # Multi-segment line (checkmark-like shape)
        SimpleLine([Point2f(100, 200), Point2f(130, 230), Point2f(180, 180)], Vec4{Float32}(0.0, 0.8, 0.0, 1.0), 3.0f0, SOLID),
    ]

    background_color = Vec4{Float32}(0.95, 0.95, 0.95, 1.0) # Light gray background

    IntrinsicColumn([
            IntrinsicHeight(Container(Text("Line Drawing Demo"))),
            Container(LineDrawContainer(lines, background_color)),
            IntrinsicHeight(Container(Text("Various line styles and shapes"))),
        ], padding=10.0, spacing=10.0)
end

Fugl.run(MyApp, title="Line Drawing Test", window_width_px=450, window_height_px=400, fps_overlay=true)
