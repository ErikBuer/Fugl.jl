struct DropdownStyle
    text_style::TextStyle
    background_color::Vec4{<:AbstractFloat}
    background_color_hover::Vec4{<:AbstractFloat}
    background_color_open::Vec4{<:AbstractFloat}
    border_color::Vec4{<:AbstractFloat}
    border_width::Float32
    corner_radius::Float32
    padding::Float32
    arrow_color::Vec4{<:AbstractFloat}
    item_height_px::Float32
    max_visible_items::Int
end

function DropdownStyle(;
    text_style=TextStyle(),
    background_color=Vec4{Float32}(1.0f0, 1.0f0, 1.0f0, 1.0f0),        # White background
    background_color_hover=Vec4{Float32}(0.95f0, 0.95f0, 0.95f0, 1.0f0), # Light gray on hover
    background_color_open=Vec4{Float32}(0.9f0, 0.9f0, 0.9f0, 1.0f0),     # Darker gray when open
    border_color=Vec4{Float32}(0.5f0, 0.5f0, 0.5f0, 1.0f0),
    border_width=1.0f0,
    corner_radius=8.0f0,
    padding=10.0f0,
    arrow_color=Vec4{Float32}(0.3f0, 0.3f0, 0.3f0, 1.0f0),
    item_height_px=30.0f0,
    max_visible_items=5
)
    return DropdownStyle(
        text_style, background_color, background_color_hover, background_color_open,
        border_color, border_width, corner_radius, padding, arrow_color,
        item_height_px, max_visible_items
    )
end