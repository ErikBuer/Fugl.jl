"""
Transform between polar coordinates (r, θ) and Cartesian coordinates (x, y).
"""

"""
Convert polar coordinates (r, θ) to Cartesian coordinates (x, y).

Automatically handles negative angles - no conversion needed!
Just pass your angles as-is (e.g., -π to π works directly).

# Arguments
- `r::Float32`: Radius
- `theta::Float32`: Angle in radians (can be negative, e.g., -π to π)
- `theta_start::Float32`: Angle offset where θ=0 points (0 = right/east, π/2 = up/north, π = left/west, 3π/2 = down/south)
- `theta_direction::Symbol`: :counterclockwise or :clockwise rotation direction
- `center_x::Float32`: Center X coordinate in Cartesian space
- `center_y::Float32`: Center Y coordinate in Cartesian space

# Returns
- `Tuple{Float32,Float32}`: Cartesian coordinates (x, y)
"""
function polar_to_cartesian(
    r::Float32,
    theta::Float32,
    theta_start::Float32,
    theta_direction::Symbol,
    center_x::Float32=0.0f0,
    center_y::Float32=0.0f0
)::Tuple{Float32,Float32}
    # Adjust theta based on rotation direction
    adjusted_theta = theta_direction == :clockwise ? -theta : theta

    # Apply theta_start offset
    final_theta = adjusted_theta + theta_start

    # Convert to Cartesian coordinates
    x = center_x + r * cos(final_theta)
    y = center_y + r * sin(final_theta)

    return (x, y)
end

"""
Convert Cartesian coordinates (x, y) to polar coordinates (r, θ).

Returns angle normalized to [0, 2π) range.

# Arguments
- `x::Float32`: X coordinate
- `y::Float32`: Y coordinate
- `theta_start::Float32`: Angle offset where θ=0 points
- `theta_direction::Symbol`: :counterclockwise or :clockwise rotation direction
- `center_x::Float32`: Center X coordinate
- `center_y::Float32`: Center Y coordinate

# Returns
- `Tuple{Float32,Float32}`: Polar coordinates (r, θ) where θ is in [0, 2π)
"""
function cartesian_to_polar(
    x::Float32,
    y::Float32,
    theta_start::Float32,
    theta_direction::Symbol,
    center_x::Float32=0.0f0,
    center_y::Float32=0.0f0
)::Tuple{Float32,Float32}
    # Translate to origin
    dx = x - center_x
    dy = y - center_y

    # Calculate radius
    r = sqrt(dx * dx + dy * dy)

    # Calculate angle
    raw_theta = atan(dy, dx)

    # Reverse theta_start offset
    adjusted_theta = raw_theta - theta_start

    # Adjust for rotation direction
    theta = theta_direction == :clockwise ? -adjusted_theta : adjusted_theta

    # Normalize to [0, 2π)
    theta = mod2pi(theta)

    return (r, theta)
end
