# Scatter plot element
struct ScatterPlotElement <: AbstractPlotElement
    x_data::Vector{Float32}
    y_data::Vector{Float32}
    fill_color::Vec4{Float32}
    border_color::Vec4{Float32}
    marker_size::Float32
    hover_marker_size::Float32
    border_width::Float32
    hover_border_width::Float32
    marker_type::MarkerType
    label::String
    muted::Bool
    hovered::Bool
end

function ScatterPlotElement(
    y_data::Vector{<:Real};
    x_data::Union{Vector{<:Real},Nothing}=nothing,
    fill_color::Vec4{Float32}=Vec4{Float32}(0.2f0, 0.2f0, 1.0f0, 1.0f0),
    border_color::Vec4{Float32}=Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 1.0f0),
    marker_size::Float32=5.0f0,
    hover_marker_size::Union{Float32,Nothing}=nothing,
    border_width::Float32=1.50f0,
    hover_border_width::Union{Float32,Nothing}=nothing,
    marker_type::MarkerType=CIRCLE,
    label::String="",
    muted::Bool=false,
    hovered::Bool=false
)
    y_f32 = Float32.(y_data)
    x_f32 = x_data === nothing ? Float32.(1:length(y_data)) : Float32.(x_data)
    hms = hover_marker_size === nothing ? marker_size : hover_marker_size
    hbw = hover_border_width === nothing ? border_width : hover_border_width
    return ScatterPlotElement(x_f32, y_f32, fill_color, border_color, marker_size, hms, border_width, hbw, marker_type, label, muted, hovered)
end

"""
Create a new ScatterPlotElement from an existing element with keyword-based modifications.
"""
function ScatterPlotElement(elem::ScatterPlotElement;
    x_data=elem.x_data,
    y_data=elem.y_data,
    fill_color=elem.fill_color,
    border_color=elem.border_color,
    marker_size=elem.marker_size,
    hover_marker_size=elem.hover_marker_size,
    border_width=elem.border_width,
    hover_border_width=elem.hover_border_width,
    marker_type=elem.marker_type,
    label=elem.label,
    muted=elem.muted,
    hovered=elem.hovered
)
    return ScatterPlotElement(x_data, y_data, fill_color, border_color, marker_size, hover_marker_size, border_width, hover_border_width, marker_type, label, muted, hovered)
end

"""
Toggle the muted state of a ScatterPlotElement.
"""
toggle_mute(elem::ScatterPlotElement) = ScatterPlotElement(elem; muted=!elem.muted)

"""
Toggle the hovered state of a ScatterPlotElement.
"""
toggle_hover(elem::ScatterPlotElement) = ScatterPlotElement(elem; hovered=!elem.hovered)