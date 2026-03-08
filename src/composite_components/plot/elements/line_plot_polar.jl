"""
Create a line plot element using polar coordinates.

In polar plots: x_data represents angle (θ), y_data represents radius (r)

# Arguments
- `r_data`: Radius values (will be stored in y_data)
- `theta_data`: Angle values in radians (will be stored in x_data)
- `color`: Line color (default: cyan-blue)
- `width`: Line width in pixels (default: 2.0)
- `line_style`: Line pattern (SOLID, DASH, DOT, etc.)
- `label`: Label for legend (default: "")

# Example
```julia
theta = range(0, 2π, length=100)
r = 1.0f0 .+ 0.5f0 .* cos.(5.0f0 .* theta)

polar_line = PolarLine(r, theta, 
    color=Vec4{Float32}(1.0, 0.0, 0.0, 1.0),
    width=2.5f0,
    label="Rose Curve"
)
```
"""
function PolarLine(
    r_data::Vector{<:Real},
    theta_data::Vector{<:Real};
    color::Vec4{Float32}=Vec4{Float32}(0.0f0, 0.5f0, 1.0f0, 1.0f0),
    width::Float32=2.0f0,
    line_style::LinePattern=SOLID,
    label::String="",
    muted::Bool=false
)::LinePlotElement
    return LinePlotElement(
        Float32.(theta_data),  # x = theta (angle)
        Float32.(r_data),      # y = r (radius)
        color,
        width,
        line_style,
        label,
        muted
    )
end
