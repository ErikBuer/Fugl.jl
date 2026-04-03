struct TooltipStyle
    text_style::TextStyle
    background_color::Vec4{<:Float32}
    border_color::Vec4{<:Float32}
    border_width::Float32
    corner_radius::Float32
    padding::Float32
    width::Float32
    anti_aliasing_width::Float32
    shadow_color::Vec4{<:Float32}
    shadow_offset::Float32
end

function TooltipStyle(;
    text_style=TextStyle(color=Vec4{Float32}(0.1f0, 0.1f0, 0.1f0, 1.0f0), size_points=12.0f0),  # Dark text
    background_color=Vec4{Float32}(0.95f0, 0.95f0, 0.8f0, 0.95f0),  # Light yellow background with slight transparency
    border_color=Vec4{Float32}(0.6f0, 0.6f0, 0.6f0, 1.0f0),         # Gray border
    border_width=1.0f0,
    corner_radius=6.0f0,
    padding=8.0f0,
    width=200.0f0,  # Default tooltip width - user configurable
    anti_aliasing_width=1.0f0,
    shadow_color=Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 0.2f0),         # Subtle black shadow
    shadow_offset=2.0f0
)
    return TooltipStyle(
        text_style, background_color, border_color, border_width, corner_radius,
        padding, width, anti_aliasing_width, shadow_color, shadow_offset
    )
end