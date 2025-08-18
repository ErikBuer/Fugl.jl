# Scatter plot element
struct ScatterPlotElement <: AbstractPlotElement
    x_data::Vector{Float32}
    y_data::Vector{Float32}
    fill_color::Vec4{Float32}
    border_color::Vec4{Float32}
    marker_size::Float32
    border_width::Float32
    marker_type::MarkerType
    label::String
end

function ScatterPlotElement(
    y_data::Vector{<:Real};
    x_data::Union{Vector{<:Real},Nothing}=nothing,
    fill_color::Vec4{Float32}=Vec4{Float32}(0.2f0, 0.2f0, 1.0f0, 1.0f0),
    border_color::Vec4{Float32}=Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 1.0f0),
    marker_size::Float32=5.0f0,
    border_width::Float32=1.50f0,
    marker_type::MarkerType=CIRCLE,
    label::String=""
)
    y_f32 = Float32.(y_data)
    x_f32 = x_data === nothing ? Float32.(1:length(y_data)) : Float32.(x_data)
    return ScatterPlotElement(x_f32, y_f32, fill_color, border_color, marker_size, border_width, marker_type, label)
end