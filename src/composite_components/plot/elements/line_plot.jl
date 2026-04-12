# Line plot element
struct LinePlotElement <: AbstractPlotElement
    x_data::Vector{Float32}
    y_data::Vector{Float32}
    color::Vec4{Float32}
    width::Float32
    hover_width::Float32  # Line width when hovered; defaults to width if not set
    line_style::LinePattern
    label::String
    muted::Bool
    hovered::Bool
end

function LinePlotElement(
    y_data::Vector{<:Real};
    x_data::Union{Vector{<:Real},Nothing}=nothing,
    color::Vec4{Float32}=Vec4{Float32}(0.2f0, 0.6f0, 0.8f0, 1.0f0),
    width::Float32=2.0f0,
    hover_width::Union{Float32,Nothing}=nothing,
    line_style::LinePattern=SOLID,
    label::String="",
    muted::Bool=false,
    hovered::Bool=false
)
    y_f32 = Float32.(y_data)
    x_f32 = x_data === nothing ? Float32.(1:length(y_data)) : Float32.(x_data)
    hw = hover_width === nothing ? width : hover_width
    return LinePlotElement(x_f32, y_f32, color, width, hw, line_style, label, muted, hovered)
end

"""
Create a new LinePlotElement from an existing element with keyword-based modifications.
"""
function LinePlotElement(elem::LinePlotElement;
    x_data=elem.x_data,
    y_data=elem.y_data,
    color=elem.color,
    width=elem.width,
    hover_width=elem.hover_width,
    line_style=elem.line_style,
    label=elem.label,
    muted=elem.muted,
    hovered=elem.hovered
)
    return LinePlotElement(x_data, y_data, color, width, hover_width, line_style, label, muted, hovered)
end

"""
Toggle the muted state of a LinePlotElement.
"""
toggle_mute(elem::LinePlotElement) = LinePlotElement(elem; muted=!elem.muted)

"""
Toggle the hovered state of a LinePlotElement.
"""
toggle_hover(elem::LinePlotElement) = LinePlotElement(elem; hovered=!elem.hovered)