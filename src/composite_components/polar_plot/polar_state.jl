"""
State management for polar plots.
"""

struct PolarState
    # Coordinate system configuration
    theta_start::Float32                    # Where θ=0 points (0 = right/east, π/2 = up/north, etc.)
    theta_direction::Symbol                 # :counterclockwise or :clockwise
    theta_range::Tuple{Float32,Float32}     # Angular range to display (e.g., (0, 2π) for full circle)

    # Radial range
    r_min::Float32                          # Minimum radius (often 0)
    r_max::Float32                          # Maximum radius
    auto_scale_r::Bool                      # Auto-calculate r_max from data

    # Grid configuration
    num_radial_circles::Int                 # Number of radial grid circles
    num_angular_lines::Int                  # Number of angular grid lines (spokes)

    # Angular label format
    angular_label_format::Symbol            # :degrees or :radians

    # Cache ID for render caching
    cache_id::UInt64
end

"""
Create PolarState with default values.
"""
function PolarState(;
    theta_start::Float32=0.0f0,                        # 0 radians = right/east
    theta_direction::Symbol=:counterclockwise,
    theta_range::Tuple{Float32,Float32}=(0.0f0, 2.0f0 * Float32(π)),  # Full circle
    r_min::Float32=0.0f0,
    r_max::Float32=1.0f0,
    auto_scale_r::Bool=true,
    num_radial_circles::Int=5,
    num_angular_lines::Int=12,                         # Every 30 degrees
    angular_label_format::Symbol=:degrees,
    cache_id::UInt64=rand(UInt64)
)::PolarState
    return PolarState(
        theta_start,
        theta_direction,
        theta_range,
        r_min,
        r_max,
        auto_scale_r,
        num_radial_circles,
        num_angular_lines,
        angular_label_format,
        cache_id
    )
end

"""
Create a new PolarState with modified fields.
"""
function PolarState(base::PolarState;
    theta_start=base.theta_start,
    theta_direction=base.theta_direction,
    theta_range=base.theta_range,
    r_min=base.r_min,
    r_max=base.r_max,
    auto_scale_r=base.auto_scale_r,
    num_radial_circles=base.num_radial_circles,
    num_angular_lines=base.num_angular_lines,
    angular_label_format=base.angular_label_format,
    cache_id=base.cache_id
)::PolarState
    return PolarState(
        theta_start,
        theta_direction,
        theta_range,
        r_min,
        r_max,
        auto_scale_r,
        num_radial_circles,
        num_angular_lines,
        angular_label_format,
        cache_id
    )
end
