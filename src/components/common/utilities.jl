"""
    generate_rectangle_vertices(x, y, width, height)

Function to generate a rectangle with specified position and size in pixel coordinates.

This function creates a rectangle defined by its top-left corner (x, y), width, and height.
"""
function generate_rectangle_vertices(x::Float32, y::Float32, width::Float32, height::Float32)::Vector{Point{2,Float32}}
    vertices = Point{2,Float32}[
        Point{2,Float32}(x, y),                    # Top-left
        Point{2,Float32}(x, y + height),           # Bottom-left
        Point{2,Float32}(x + width, y + height),   # Bottom-right
        Point{2,Float32}(x + width, y),            # Top-right   
    ]
    return vertices
end

"""
    inside_component(view, x, y, width, height, mouse_x, mouse_y) -> Bool

Whether `(mouse_x, mouse_y)` is over the rectangle `(x, y, width, height)` **and** within the
currently active hit-test clip (see `pointer_in_clip`/`with_input_clip`). Only ever called
during the `detect_click` input pass, so consulting the clip makes every pointer-target
decision respect the same clipping the renderer applies — content scrolled out of a viewport
is not "inside" its enclosing component even though its layout rect extends past the viewport.
When no clip is active (the common case, and the render/screenshot path) this reduces to a plain
bounds test.
"""
function inside_component(view::AbstractView, x::Float32, y::Float32, width::Float32, height::Float32, mouse_x::Float32, mouse_y::Float32)::Bool
    return mouse_x >= x && mouse_x <= x + width && mouse_y >= y && mouse_y <= y + height &&
           pointer_in_clip(mouse_x, mouse_y)
end