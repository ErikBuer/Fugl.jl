"""
Create a stem plot element using polar coordinates.

In polar plots: x_data represents angle (θ), y_data represents radius (r)
Stems extend from baseline (radial value) to each data point.

# Arguments
- `r_data`: Radius values (will be stored in y_data)
- `theta_data`: Angle values in radians (will be stored in x_data)
- `line_color`: Stem line color (default: cyan-blue)
- `fill_color`: Marker fill color (default: cyan-blue)
- `border_color`: Marker border color (default: black)
- `line_width`: Stem line width in pixels (default: 1.5)
- `marker_size`: Marker size in pixels (default: 8.0)
- `border_width`: Marker border width in pixels (default: 1.0)
- `marker_type`: Marker shape (CIRCLE, SQUARE, TRIANGLE, etc.)
- `baseline`: Radial baseline where stems originate (default: 0.0 = center)
- `label`: Label for legend (default: "")

# Example
```julia
theta = range(0, 2π, length=12)
r = 0.5f0 .+ 0.3f0 .* sin.(3.0f0 .* theta)

stem = PolarStem(r, theta,
    line_color=Vec4{Float32}(0.0, 1.0, 0.0, 1.0),
    fill_color=Vec4{Float32}(0.0, 1.0, 0.0, 1.0),
    baseline=0.2f0,  # Stems start at r=0.2
    label="Stem Data"
)
```
"""
function PolarStem(
    r_data::Vector{<:Real},
    theta_data::Vector{<:Real};
    line_color::Vec4{Float32}=Vec4{Float32}(0.0f0, 0.5f0, 1.0f0, 1.0f0),
    fill_color::Vec4{Float32}=Vec4{Float32}(0.0f0, 0.5f0, 1.0f0, 1.0f0),
    border_color::Vec4{Float32}=Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 1.0f0),
    line_width::Float32=1.5f0,
    marker_size::Float32=8.0f0,
    border_width::Float32=1.0f0,
    marker_type::MarkerType=CIRCLE,
    baseline::Float32=0.0f0,  # Radial baseline (typically 0 = center)
    label::String="",
    muted::Bool=false
)::StemPlotElement
    return StemPlotElement(
        Float32.(theta_data),  # x = theta (angle)
        Float32.(r_data),      # y = r (radius)
        line_color,
        fill_color,
        border_color,
        line_width,
        marker_size,
        border_width,
        marker_type,
        baseline,
        label,
        muted
    )
end
