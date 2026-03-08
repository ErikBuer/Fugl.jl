"""
Create a scatter plot element using polar coordinates.

In polar plots: x_data represents angle (θ), y_data represents radius (r)

# Arguments
- `r_data`: Radius values (will be stored in y_data)
- `theta_data`: Angle values in radians (will be stored in x_data)
- `fill_color`: Marker fill color (default: cyan-blue)
- `border_color`: Marker border color (default: black)
- `marker_size`: Marker size in pixels (default: 8.0)
- `border_width`: Border width in pixels (default: 1.0)
- `marker_type`: Marker shape (CIRCLE, SQUARE, TRIANGLE, etc.)
- `label`: Label for legend (default: "")

# Example
```julia
theta = range(0, 2π, length=16)
r = 0.6f0 .+ 0.3f0 .* rand(Float32, 16)

scatter = PolarScatter(r, theta,
    fill_color=Vec4{Float32}(1.0, 0.0, 0.0, 1.0),
    marker_size=10.0f0,
    label="Data Points"
)
```
"""
function PolarScatter(
    r_data::Vector{<:Real},
    theta_data::Vector{<:Real};
    fill_color::Vec4{Float32}=Vec4{Float32}(0.0f0, 0.5f0, 1.0f0, 1.0f0),
    border_color::Vec4{Float32}=Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 1.0f0),
    marker_size::Float32=8.0f0,
    border_width::Float32=1.0f0,
    marker_type::MarkerType=CIRCLE,
    label::String="",
    muted::Bool=false
)::ScatterPlotElement
    return ScatterPlotElement(
        Float32.(theta_data),  # x = theta (angle)
        Float32.(r_data),      # y = r (radius)
        fill_color,
        border_color,
        marker_size,
        border_width,
        marker_type,
        label,
        muted
    )
end
