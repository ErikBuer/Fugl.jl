"""
A button containing text only.
"""
function TextButton(text::String;
    on_click::Function=() -> nothing,
    on_mouse_down::Function=() -> nothing,
    container_style=ContainerStyle(),
    text_style=TextStyle(),
    enable_hover::Bool=true,
    enable_pressed::Bool=true
)
    # Create hover style if enabled
    hover_style = if enable_hover
        ContainerStyle(
            background_color=Vec4{Float32}(0.9f0, 0.9f0, 0.92f0, 1.0f0),  # Slightly lighter on hover
            border_color=container_style.border_color,
            border_width=container_style.border_width,
            padding=container_style.padding,
            corner_radius=container_style.corner_radius,
            anti_aliasing_width=container_style.anti_aliasing_width
        )
    else
        nothing
    end

    # Create pressed style if enabled
    pressed_style = if enable_pressed
        ContainerStyle(
            background_color=Vec4{Float32}(0.7f0, 0.7f0, 0.72f0, 1.0f0),  # Darker when pressed
            border_color=container_style.border_color,
            border_width=container_style.border_width + 1.0f0,            # Thicker border when pressed
            padding=container_style.padding,
            corner_radius=container_style.corner_radius,
            anti_aliasing_width=container_style.anti_aliasing_width
        )
    else
        nothing
    end

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