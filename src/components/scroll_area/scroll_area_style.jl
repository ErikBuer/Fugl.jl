"""
Style for scroll area appearance
"""
struct ScrollAreaStyle
    scrollbar_width::Float32
    scrollbar_color::Vec4f
    scrollbar_background_color::Vec4f
    scrollbar_hover_color::Vec4f
    corner_color::Vec4f  # Color for the corner where scrollbars meet
end

function ScrollAreaStyle(;
    scrollbar_width::Float32=12.0f0,
    scrollbar_color::Vec4f=Vec4f(0.6, 0.6, 0.6, 1.0),
    scrollbar_background_color::Vec4f=Vec4f(0.9, 0.9, 0.9, 1.0),
    scrollbar_hover_color::Vec4f=Vec4f(0.4, 0.4, 0.4, 1.0),
    corner_color::Vec4f=Vec4f(0.9, 0.9, 0.9, 1.0)
)
    return ScrollAreaStyle(
        scrollbar_width, scrollbar_color, scrollbar_background_color,
        scrollbar_hover_color, corner_color
    )
end