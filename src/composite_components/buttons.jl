"""
A button containing text only.
"""
function TextButton(text::String;
    on_click::Function=() -> nothing,
    on_mouse_down::Function=() -> nothing,
    container_style=ContainerStyle(),
    hover_style::Union{Nothing,ContainerStyle}=nothing,
    pressed_style::Union{Nothing,ContainerStyle}=nothing,
    text_style=TextStyle(),
)
    return Container(Text(text, style=text_style), style=container_style, hover_style=hover_style, pressed_style=pressed_style, on_click=on_click, on_mouse_down=on_mouse_down)
end

"""
A button consisting of the icon only.
"""
function IconButton(
    image_path::String;
    on_click::Function=() -> nothing
)
    return Container(
        Image(image_path),
        style=ContainerStyle(background_color=Vec4{Float32}(0.0, 0.0, 0.0, 0.0), border_color=Vec4{Float32}(0.0, 0.0, 0.0, 0.0)),
        on_click=on_click
    )
end