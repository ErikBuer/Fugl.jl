"""
A button containing text only.
"""
function TextButton(text::String;
    on_click::Function=() -> nothing,
    container_style=ContainerStyle(),
    text_style=TextStyle()
)
    return Container(Text(text, style=text_style), style=container_style, on_click=on_click)
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