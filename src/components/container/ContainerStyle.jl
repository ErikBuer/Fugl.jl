struct ContainerStyle
    background_color::Vec4{<:Float32} #RGBA color
    border_color::Vec4{<:Float32} #RGBA color
    border_width::Float32
    padding::Float32
    corner_radius::Float32
    anti_aliasing_width::Float32
end

function ContainerStyle(;
    background_color=Vec4{Float32}(0.88f0, 0.875f0, 0.88f0, 1.0f0),
    border_color=Vec4{Float32}(0.5f0, 0.5f0, 0.5f0, 1.0f0),
    border_width=1.0f0,
    padding::Float32=6f0,
    corner_radius::Float32=5.0f0,
    anti_aliasing_width::Float32=1.0f0
)
    return ContainerStyle(background_color, border_color, border_width, padding, corner_radius, anti_aliasing_width)
end