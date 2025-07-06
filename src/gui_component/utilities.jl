using IndirectArrays


"""
    generate_rectangle_vertices(x, y, width, height)

Function to generate a rectangle with specified position and size in pixel coordinates.

This function creates a rectangle defined by its top-left corner (x, y), width, and height.
"""
function generate_rectangle_vertices(x, y, width, height)::Vector{Point{2,Float32}}
    vertices = Point{2,Float32}[
        Point{2,Float32}(x, y),                    # Top-left
        Point{2,Float32}(x, y + height),           # Bottom-left
        Point{2,Float32}(x + width, y + height),   # Bottom-right
        Point{2,Float32}(x + width, y),            # Top-right   
    ]
    return vertices
end

function inside_component(view::AbstractView, x::AbstractFloat, y::AbstractFloat, width::AbstractFloat, height::AbstractFloat, mouse_x::AbstractFloat, mouse_y::AbstractFloat)::Bool
    return mouse_x >= x && mouse_x <= x + width && mouse_y >= y && mouse_y <= y + height
end