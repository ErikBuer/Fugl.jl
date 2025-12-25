"""
A button containing text only.
"""
function TextButton(text::String;
    on_click::Function=() -> nothing,
    on_mouse_down::Function=() -> nothing,
    container_style=ContainerStyle(),
    hover_style::Union{Nothing,ContainerStyle}=nothing,
    pressed_style::Union{Nothing,ContainerStyle}=nothing,
    disabled::Bool=false,
    disabled_style::Union{Nothing,ContainerStyle}=nothing,
    text_style=TextStyle(),
    disabled_text_style::Union{Nothing,TextStyle}=nothing,
    interaction_state::Union{Nothing,InteractionState}=nothing,
    on_interaction_state_change::Function=(new_state) -> nothing
)
    # Choose text style based on disabled state
    active_text_style = if disabled && disabled_text_style !== nothing
        disabled_text_style
    else
        text_style
    end

    return Container(
        Text(text, style=active_text_style),
        style=container_style,
        hover_style=hover_style,
        pressed_style=pressed_style,
        disabled=disabled,
        disabled_style=disabled_style,
        on_click=on_click,
        on_mouse_down=on_mouse_down,
        interaction_state=interaction_state,
        on_interaction_state_change=on_interaction_state_change
    )
end

"""
A button consisting of the icon only.
"""
function IconButton(
    image_path::String;
    on_click::Function=() -> nothing,
    container_style::Union{Nothing,ContainerStyle}=nothing,
    hover_style::Union{Nothing,ContainerStyle}=nothing,
    pressed_style::Union{Nothing,ContainerStyle}=nothing,
    disabled::Bool=false,
    disabled_style::Union{Nothing,ContainerStyle}=nothing,
    interaction_state::Union{Nothing,InteractionState}=nothing,
    on_interaction_state_change::Function=(new_state) -> nothing
)
    # Default transparent container style if none provided
    default_container_style = container_style === nothing ? ContainerStyle(
        background_color=Vec4{Float32}(0.0, 0.0, 0.0, 0.0),
        border_color=Vec4{Float32}(0.0, 0.0, 0.0, 0.0)
    ) : container_style

    return Container(
        Image(image_path),
        style=default_container_style,
        hover_style=hover_style,
        pressed_style=pressed_style,
        disabled=disabled,
        disabled_style=disabled_style,
        on_click=on_click,
        interaction_state=interaction_state,
        on_interaction_state_change=on_interaction_state_change
    )
end