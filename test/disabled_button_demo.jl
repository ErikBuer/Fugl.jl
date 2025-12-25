using Fugl

# Dark mode button styles
const BUTTON_STYLE = ContainerStyle(
    background_color=Vec4f(0.08, 0.10, 0.14, 1.0f0),
    border_color=Vec4f(0.15, 0.18, 0.25, 1.0f0),
    border_width=1.5f0,
    padding=12.0f0,
    corner_radius=6.0f0
)

const BUTTON_HOVER_STYLE = ContainerStyle(
    background_color=Vec4f(0.12, 0.14, 0.18, 1.0f0),
    border_color=Vec4f(0.20, 0.23, 0.30, 1.0f0),
    border_width=2.0f0,
    padding=12.0f0,
    corner_radius=6.0f0
)

const BUTTON_PRESSED_STYLE = ContainerStyle(
    background_color=Vec4f(0.06, 0.08, 0.12, 1.0f0),
    border_color=Vec4f(0.12, 0.5, 0.22, 1.0f0),
    border_width=1.5f0,
    padding=12.0f0,
    corner_radius=6.0f0
)

const BUTTON_DISABLED_STYLE = ContainerStyle(
    background_color=Vec4f(0.05, 0.05, 0.06, 1.0f0),
    border_color=Vec4f(0.10, 0.10, 0.12, 1.0f0),
    border_width=1.0f0,
    padding=12.0f0,
    corner_radius=6.0f0
)

# Dark mode card style
const DARK_CARD_STYLE = ContainerStyle(
    background_color=Vec4f(0.15, 0.15, 0.18, 1.0),
    border_color=Vec4f(0.25, 0.25, 0.30, 1.0),
    border_width=1.5f0,
    padding=12.0f0,
    corner_radius=6.0f0,
    anti_aliasing_width=1.0f0
)

# Dark mode title style
const DARK_TITLE_STYLE = TextStyle(
    size_px=18,
    color=Vec4f(0.9, 0.9, 0.95, 1.0)
)

# Text styles
const LIGHT_TEXT_STYLE = TextStyle(color=Vec4f(0.9, 0.9, 0.95, 1.0))
const DISABLED_TEXT_STYLE = TextStyle(color=Vec4f(0.4, 0.4, 0.45, 1.0))

# Button interaction states
button1 = Ref(InteractionState())
button2 = Ref(InteractionState())

function test_disabled_buttons()
    function MyApp()
        Card(
            "Dark Mode Button States",
            Column(
                [
                    # Interactive button (enabled)
                    TextButton("Interactive Button",
                        on_click=() -> println("Interactive button clicked!"),
                        container_style=BUTTON_STYLE,
                        hover_style=BUTTON_HOVER_STYLE,
                        pressed_style=BUTTON_PRESSED_STYLE,
                        text_style=LIGHT_TEXT_STYLE,
                        interaction_state=button1[],
                        on_interaction_state_change=(new_state) -> button1[] = new_state
                    ),

                    # Disabled button
                    TextButton("Disabled Button",
                        disabled=true,
                        on_click=() -> println("This shouldn't print - button is disabled"),
                        container_style=BUTTON_STYLE,
                        hover_style=BUTTON_HOVER_STYLE,
                        pressed_style=BUTTON_PRESSED_STYLE,
                        disabled_style=BUTTON_DISABLED_STYLE,
                        text_style=LIGHT_TEXT_STYLE,
                        disabled_text_style=DISABLED_TEXT_STYLE,
                        interaction_state=button2[],
                        on_interaction_state_change=(new_state) -> button2[] = new_state
                    ),
                ],
                spacing=12.0f0),
            style=DARK_CARD_STYLE,
            title_style=DARK_TITLE_STYLE
        )
    end

    Fugl.run(MyApp, title="Disabled Buttons Test", window_width_px=400, window_height_px=300)
end

test_disabled_buttons()