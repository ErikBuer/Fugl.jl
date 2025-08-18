"""
Simple 2D rectangle type.
"""
struct Rect2f
    x::Float32
    y::Float32
    width::Float32
    height::Float32
end

"""
Constructor convenience function for different numeric types
"""
Rect2f(x::Real, y::Real, width::Real, height::Real) = Rect2f(Float32(x), Float32(y), Float32(width), Float32(height))

# Utility functions for Rect2f
function min_corner(rect::Rect2f)::Tuple{Float32,Float32}
    return (rect.x, rect.y)
end

function max_corner(rect::Rect2f)::Tuple{Float32,Float32}
    return (rect.x + rect.width, rect.y + rect.height)
end

function center(rect::Rect2f)::Tuple{Float32,Float32}
    return (rect.x + rect.width / 2, rect.y + rect.height / 2)
end