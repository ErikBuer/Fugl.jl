using Fugl
using Fugl: Text, TextButton


# Modal state for position tracking (nothing = centered)
modal_state = Ref(ModalState(
    offset_x=nothing,
    offset_y=nothing
))

# Dark mode style for modal background overlay
modal_style = ModalStyle(
    background_color=Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 0.5f0)
)

# Dark mode button styles
button_normal_style = ContainerStyle(
    background_color=Vec4f(0.15, 0.35, 0.65, 1.0),
    border_color=Vec4f(0.1, 0.25, 0.55, 1.0),
    border_width=2.0f0,
    padding=12.0f0,
    corner_radius=6.0f0
)

button_hover_style = ContainerStyle(
    background_color=Vec4f(0.25, 0.45, 0.75, 1.0),
    border_color=Vec4f(0.2, 0.35, 0.65, 1.0),
    border_width=2.0f0,
    padding=12.0f0,
    corner_radius=6.0f0
)

button_pressed_style = ContainerStyle(
    background_color=Vec4f(0.1, 0.25, 0.55, 1.0),
    border_color=Vec4f(0.05, 0.15, 0.45, 1.0),
    border_width=2.0f0,
    padding=12.0f0,
    corner_radius=6.0f0
)

# Dark mode text styles
light_text_style = TextStyle(color=Vec4f(0.9, 0.9, 0.95, 1.0))

# Dark mode card styles
background_card_style = ContainerStyle(
    background_color=Vec4f(0.12, 0.12, 0.15, 1.0),
    border_color=Vec4f(0.2, 0.2, 0.25, 1.0),
    border_width=1.5f0,
    padding=12.0f0,
    corner_radius=6.0f0
)

modal_card_style = ContainerStyle(
    background_color=Vec4f(0.18, 0.18, 0.22, 1.0),
    border_color=Vec4f(0.3, 0.3, 0.35, 1.0),
    border_width=2.0f0,
    padding=16.0f0,
    corner_radius=8.0f0
)

title_text_style = TextStyle(size_px=18, color=Vec4f(0.9, 0.9, 0.95, 1.0))

# Button interaction state
button_state = Ref(InteractionState())

function MyApp()
    # Modal wraps both the modal content and the background content
    Modal(
        Card(
            "Background Content",
            Fugl.Text("This content is behind the modal overlay.", style=light_text_style),
            style=background_card_style,
            title_style=title_text_style
        ),
        Card(
            "Draggable Modal",
            IntrinsicColumn([
                    Fugl.Text("This is a draggable modal overlay.", style=light_text_style),
                    Fugl.Text("Click and drag the modal to move it around.", style=light_text_style),
                    IntrinsicHeight(
                        TextButton(
                            "Reset Position";
                            on_click=() -> begin
                                modal_state[] = ModalState(
                                    offset_x=nothing,
                                    offset_y=nothing
                                )
                            end,
                            text_style=light_text_style,
                            container_style=button_normal_style,
                            hover_style=button_hover_style,
                            pressed_style=button_pressed_style,
                            interaction_state=button_state[],
                            on_interaction_state_change=(new_state) -> button_state[] = new_state
                        )
                    )
                ], spacing=12.0f0),
            style=modal_card_style,
            title_style=title_text_style
        ),
        child_width=350.0f0,
        child_height=200.0f0,
        state=modal_state[],
        style=modal_style,
        on_state_change=(new_state) -> modal_state[] = new_state,
        on_click_outside=() -> println("Clicked outside the modal!")
    )
end

Fugl.run(MyApp, title="Modal Demo", window_width_px=800, window_height_px=600, fps_overlay=true)
