"""
Unified style structure for text editors (CodeEditor and TextBox).
This replaces the separate CodeEditorStyle and TextBoxStyle structures.
"""

mutable struct TextEditorStyle
    text_style::TextStyle
    background_color_focused::Vec4{<:AbstractFloat}
    background_color_unfocused::Vec4{<:AbstractFloat}
    border_color::Vec4{<:AbstractFloat}
    border_width_px::Float32
    corner_radius_px::Float32
    padding_px::Float32
    cursor_color::Vec4{<:AbstractFloat}
    selection_color::Vec4{<:AbstractFloat}
end

"""
Create a TextEditorStyle with default values suitable for CodeEditor (dark theme).
"""
function CodeEditorStyle(;
    text_style=TextStyle(),
    background_color_focused=Vec4{Float32}(0.05f0, 0.05f0, 0.1f0, 1.0f0),  # Dark blue when focused
    background_color_unfocused=Vec4{Float32}(0.1f0, 0.1f0, 0.15f0, 1.0f0), # Darker when not focused
    border_color=Vec4{Float32}(0.3f0, 0.3f0, 0.4f0, 1.0f0),
    border_width_px=1.0f0,
    corner_radius_px=8.0f0,
    padding_px=10.0f0,
    cursor_color=Vec4{Float32}(1.0f0, 1.0f0, 1.0f0, 0.8f0),  # White cursor for visibility on dark background
    selection_color=Vec4{Float32}(0.4f0, 0.6f0, 0.9f0, 0.5f0)  # Light blue selection color
)
    return TextEditorStyle(text_style, background_color_focused, background_color_unfocused, border_color, border_width_px, corner_radius_px, padding_px, cursor_color, selection_color)
end

"""
Create a TextEditorStyle with default values suitable for TextBox (light theme).
"""
function TextBoxStyle(;
    text_style=TextStyle(),
    background_color_focused=Vec4{Float32}(1.0f0, 1.0f0, 1.0f0, 1.0f0),    # White when focused
    background_color_unfocused=Vec4{Float32}(0.95f0, 0.95f0, 0.95f0, 1.0f0), # Light gray when not focused
    border_color=Vec4{Float32}(0.3f0, 0.3f0, 0.3f0, 1.0f0),
    border_width_px=1.0f0,
    corner_radius_px=8.0f0,
    padding_px=10.0f0,
    cursor_color=Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 0.8f0),  # Black cursor for visibility on white background
    selection_color=Vec4{Float32}(0.4f0, 0.6f0, 0.9f0, 0.5f0)  # Light blue selection color
)
    return TextEditorStyle(text_style, background_color_focused, background_color_unfocused, border_color, border_width_px, corner_radius_px, padding_px, cursor_color, selection_color)
end

"""
Generic constructor for TextEditorStyle with all parameters.
"""
function TextEditorStyle(;
    text_style=TextStyle(),
    background_color_focused=Vec4{Float32}(1.0f0, 1.0f0, 1.0f0, 1.0f0),
    background_color_unfocused=Vec4{Float32}(0.95f0, 0.95f0, 0.95f0, 1.0f0),
    border_color=Vec4{Float32}(0.3f0, 0.3f0, 0.3f0, 1.0f0),
    border_width_px=1.0f0,
    corner_radius_px=8.0f0,
    padding_px=10.0f0,
    cursor_color=Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 0.8f0),
    selection_color=Vec4{Float32}(0.4f0, 0.6f0, 0.9f0, 0.5f0)
)
    return TextEditorStyle(text_style, background_color_focused, background_color_unfocused, border_color, border_width_px, corner_radius_px, padding_px, cursor_color, selection_color)
end
