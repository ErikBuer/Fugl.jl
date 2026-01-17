# Line plot element
struct LinePlotElement <: AbstractPlotElement
    x_data::Vector{Float32}
    y_data::Vector{Float32}
    color::Vec4{Float32}
    width::Float32
    line_style::LinePattern
    label::String
end

function LinePlotElement(
    y_data::Vector{<:Real};
    x_data::Union{Vector{<:Real},Nothing}=nothing,
    color::Vec4{Float32}=Vec4{Float32}(0.2f0, 0.6f0, 0.8f0, 1.0f0),
    width::Float32=2.0f0,
    line_style::LinePattern=SOLID,
    label::String=""
)
    y_f32 = Float32.(y_data)
    x_f32 = x_data === nothing ? Float32.(1:length(y_data)) : Float32.(x_data)
    return LinePlotElement(x_f32, y_f32, color, width, line_style, label)
end