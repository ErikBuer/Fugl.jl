struct FloatingMenuStyle
    text_style::TextStyle
    background_color::Vec4{<:Float32}
    hover_color::Vec4{<:Float32}
    pressed_color::Vec4{<:Float32}
    border_color::Vec4{<:Float32}
    border_width::Float32
    corner_radius::Float32
    padding::Float32
    item_height_px::Float32
    max_visible_items::Int
end

function FloatingMenuStyle(;
    text_style=TextStyle(),
    background_color=Vec4{Float32}(1.0f0, 1.0f0, 1.0f0, 1.0f0),
    hover_color=Vec4{Float32}(0.9f0, 0.9f0, 0.9f0, 1.0f0),
    pressed_color=Vec4{Float32}(0.8f0, 0.8f0, 0.8f0, 1.0f0),
    border_color=Vec4{Float32}(0.5f0, 0.5f0, 0.5f0, 1.0f0),
    border_width=1.0f0,
    corner_radius=8.0f0,
    padding=6.0f0,
    item_height_px=30.0f0,
    max_visible_items=6
)
    return FloatingMenuStyle(
        text_style, background_color, hover_color, pressed_color, border_color,
        border_width, corner_radius, padding, item_height_px, max_visible_items
    )
end
