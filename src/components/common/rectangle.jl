"""
Simple 2D rectangle type.
"""
struct Rectangle
    x::Float32
    y::Float32
    width::Float32
    height::Float32
end

"""
Constructor convenience function for different numeric types
"""
Rectangle(x::Real, y::Real, width::Real, height::Real) = Rectangle(Float32(x), Float32(y), Float32(width), Float32(height))

# Utility functions for Rectangle
function min_corner(rect::Rectangle)::Tuple{Float32,Float32}
    return (rect.x, rect.y)
end

function max_corner(rect::Rectangle)::Tuple{Float32,Float32}
    return (rect.x + rect.width, rect.y + rect.height)
end

function center(rect::Rectangle)::Tuple{Float32,Float32}
    return (rect.x + rect.width / 2, rect.y + rect.height / 2)
end