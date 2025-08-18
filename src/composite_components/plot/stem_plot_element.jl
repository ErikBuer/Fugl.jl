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
end

function StemPlotElement(
    y_data::Vector{<:Real};
    x_data::Union{Vector{<:Real},Nothing}=nothing,
    line_color::Vec4{Float32}=Vec4{Float32}(0.2f0, 0.2f0, 1.0f0, 1.0f0),
    fill_color::Vec4{Float32}=Vec4{Float32}(0.2f0, 0.2f0, 1.0f0, 1.0f0),
    border_color::Vec4{Float32}=Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 0.0f0),
    line_width::Float32=2.0f0,
    marker_size::Float32=5.0f0,
    border_width::Float32=0.0f0,
    marker_type::MarkerType=CIRCLE,
    baseline::Float32=0.0f0,
    label::String=""
)
    y_f32 = Float32.(y_data)
    x_f32 = x_data === nothing ? Float32.(1:length(y_data)) : Float32.(x_data)
    return StemPlotElement(x_f32, y_f32, line_color, fill_color, border_color, line_width, marker_size, border_width, marker_type, baseline, label)
end