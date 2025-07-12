"""
A button containing text only.
"""
function TextButton(text::String; style=ContainerStyle(), on_click::Function=() -> nothing)
    return Container(Text(text), style=style, on_click=on_click)
end

"""
A button consisting of the icon only.
"""
function IconButton(
    image_path::String;
    width_px::Union{Nothing,Float32}=nothing,
    height_px::Union{Nothing,Float32}=nothing,
    on_click::Function=() -> nothing
)
    return Container(
        Image(image_path; width_px=width_px, height_px=height_px),
        style=ContainerStyle(background_color=Vec4{Float32}(0.0, 0.0, 0.0, 0.0), border_color=Vec4{Float32}(0.0, 0.0, 0.0, 0.0)),
        on_click=on_click
    )
end