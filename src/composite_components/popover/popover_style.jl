struct PopoverStyle
    background_color::Vec4{<:Float32}
    border_color::Vec4{<:Float32}
    border_width::Float32
    corner_radius::Float32
    padding::Float32
    anti_aliasing_width::Float32
    shadow_color::Vec4{<:Float32}
    shadow_offset::Float32
end

function PopoverStyle(;
    background_color=Vec4{Float32}(1.0f0, 1.0f0, 1.0f0, 1.0f0),
    border_color=Vec4{Float32}(0.6f0, 0.6f0, 0.6f0, 1.0f0),
    border_width=1.0f0,
    corner_radius=6.0f0,
    padding=8.0f0,
    anti_aliasing_width=1.0f0,
    shadow_color=Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 0.2f0),
    shadow_offset=2.0f0
)
    return PopoverStyle(
        background_color, border_color, border_width, corner_radius,
        padding, anti_aliasing_width, shadow_color, shadow_offset
    )
end
