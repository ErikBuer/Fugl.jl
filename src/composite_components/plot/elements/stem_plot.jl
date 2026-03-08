struct StemPlotElement <: AbstractPlotElement
    x_data::Vector{Float32}
    y_data::Vector{Float32}
    line_color::Vec4{Float32}
    fill_color::Vec4{Float32}
    border_color::Vec4{Float32}
    line_width::Float32
    marker_size::Float32
    border_width::Float32
    marker_type::MarkerType
    baseline::Float32  # Y value for stem baseline
    label::String
    muted::Bool
end

function StemPlotElement(
    y_data::Vector{<:Real};
    x_data::Union{Vector{<:Real},Nothing}=nothing,
    line_color::Vec4{Float32}=Vec4{Float32}(0.28f0, 0.4f0, 0.74f0, 1.0f0),
    fill_color::Vec4{Float32}=Vec4{Float32}(0.28f0, 0.4f0, 0.74f0, 1.0f0),
    border_color::Vec4{Float32}=Vec4{Float32}(0.28f0, 0.4f0, 0.74f0, 1.0f0),
    line_width::Float32=2.5f0,
    marker_size::Float32=5.0f0,
    border_width::Float32=0.0f0,
    marker_type::MarkerType=CIRCLE,
    baseline::Float32=0.0f0,
    label::String="",
    muted::Bool=false
)
    y_f32 = Float32.(y_data)
    x_f32 = x_data === nothing ? Float32.(1:length(y_data)) : Float32.(x_data)
    return StemPlotElement(x_f32, y_f32, line_color, fill_color, border_color, line_width, marker_size, border_width, marker_type, baseline, label, muted)
end

"""
Create a new StemPlotElement from an existing element with keyword-based modifications.
"""
function StemPlotElement(elem::StemPlotElement;
    x_data=elem.x_data,
    y_data=elem.y_data,
    line_color=elem.line_color,
    fill_color=elem.fill_color,
    border_color=elem.border_color,
    line_width=elem.line_width,
    marker_size=elem.marker_size,
    border_width=elem.border_width,
    marker_type=elem.marker_type,
    baseline=elem.baseline,
    label=elem.label,
    muted=elem.muted
)
    return StemPlotElement(x_data, y_data, line_color, fill_color, border_color, line_width, marker_size, border_width, marker_type, baseline, label, muted)
end

"""
Toggle the muted state of a StemPlotElement.
"""
toggle_mute(elem::StemPlotElement) = StemPlotElement(elem; muted=!elem.muted)