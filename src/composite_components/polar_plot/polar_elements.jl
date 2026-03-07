"""
Polar plot element types.
"""

abstract type AbstractPolarElement end

"""
Line plot in polar coordinates.

Data is specified as (r, θ) pairs where:
- r: radius values
- θ: angle values in radians
"""
struct PolarLineElement <: AbstractPolarElement
    r_data::Vector{Float32}
    theta_data::Vector{Float32}
    color::Vec4f
    width::Float32
    line_style::LinePattern
end

"""
Create a polar line plot element.
"""
function PolarLine(
    r_data::Vector{<:Real},
    theta_data::Vector{<:Real};
    color::Vec4f=Vec4f(0.0, 0.5, 1.0, 1.0),
    width::Float32=2.0f0,
    line_style::LinePattern=SOLID
)::PolarLineElement
    return PolarLineElement(
        Float32.(r_data),
        Float32.(theta_data),
        color,
        width,
        line_style
    )
end

"""
Scatter plot in polar coordinates.

Data is specified as (r, θ) pairs where:
- r: radius values
- θ: angle values in radians
"""
struct PolarScatterElement <: AbstractPolarElement
    r_data::Vector{Float32}
    theta_data::Vector{Float32}
    fill_color::Vec4f
    border_color::Vec4f
    marker_size::Float32
    border_width::Float32
    marker_type::MarkerType
end

"""
Create a polar scatter plot element.
"""
function PolarScatter(
    r_data::Vector{<:Real},
    theta_data::Vector{<:Real};
    fill_color::Vec4f=Vec4f(0.0, 0.5, 1.0, 1.0),
    border_color::Vec4f=Vec4f(0.0, 0.0, 0.0, 1.0),
    marker_size::Float32=8.0f0,
    border_width::Float32=1.0f0,
    marker_type::MarkerType=CIRCLE
)::PolarScatterElement
    return PolarScatterElement(
        Float32.(r_data),
        Float32.(theta_data),
        fill_color,
        border_color,
        marker_size,
        border_width,
        marker_type
    )
end
