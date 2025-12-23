using Fugl

# Dark theme color palette - defined once outside function
const DARK_BG = Vec4f(0.08, 0.08, 0.08, 1.0)
const DARK_SURFACE = Vec4f(0.15, 0.15, 0.18, 1.0)
const DARK_HOVER = Vec4f(0.22, 0.22, 0.28, 1.0)
const DARK_PRESSED = Vec4f(0.1, 0.1, 0.12, 1.0)
const DARK_BORDER = Vec4f(0.3, 0.3, 0.3, 1.0)
const DARK_TEXT = Vec4f(0.9, 0.9, 0.9, 1.0)
const ACCENT_BLUE = Vec4f(0.3, 0.5, 0.8, 1.0)
const ACCENT_RED = Vec4f(0.8, 0.3, 0.3, 1.0)

# Pre-defined styles to avoid recreation every frame
const DEFAULT_STYLE = ContainerStyle(
    background_color=DARK_SURFACE,
    border_color=DARK_BORDER,
    border_width=1.0f0,
    padding=12.0f0,
    corner_radius=6.0f0
)

const DEFAULT_HOVER_STYLE = ContainerStyle(
    background_color=DARK_HOVER,
    border_color=Vec4f(0.4, 0.4, 0.4, 1.0),
    border_width=1.0f0,
    padding=12.0f0,
    corner_radius=6.0f0
)

const DEFAULT_PRESSED_STYLE = ContainerStyle(
    background_color=DARK_PRESSED,
    border_color=Vec4f(0.5, 0.5, 0.5, 1.0),
    border_width=2.0f0,
    padding=12.0f0,
    corner_radius=6.0f0
)

const BUTTON_TEXT_STYLE = TextStyle(
    color=DARK_TEXT,
    size_px=14
)

const CUSTOM_STYLE = ContainerStyle(
    background_color=DARK_SURFACE,
    border_color=DARK_BORDER,
    border_width=2.0f0,
    padding=14.0f0,
    corner_radius=8.0f0
)

const CUSTOM_HOVER_STYLE = ContainerStyle(
    background_color=ACCENT_BLUE,  # Blue on hover
    border_color=Vec4f(0.2, 0.4, 0.7, 1.0),
    border_width=2.0f0,
    padding=14.0f0,
    corner_radius=8.0f0
)

const CUSTOM_PRESSED_STYLE = ContainerStyle(
    background_color=ACCENT_RED,  # Red when pressed
    border_color=Vec4f(0.7, 0.2, 0.2, 1.0),
    border_width=3.0f0,
    padding=14.0f0,
    corner_radius=8.0f0
)

const CUSTOM_TEXT_STYLE = TextStyle(
    color=Vec4f(1.0, 1.0, 1.0, 1.0),
    size_px=14
)

const TITLE_TEXT_STYLE = TextStyle(
    color=DARK_TEXT,
    size_px=16
)

const INFO_TEXT_STYLE = TextStyle(
    color=Vec4f(0.7, 0.7, 0.7, 1.0),
    size_px=12
)

const HELP_TEXT_STYLE = TextStyle(
    color=Vec4f(0.6, 0.6, 0.6, 1.0),
    size_px=10
)

const INFO_CONTAINER_STYLE = ContainerStyle(
    background_color=Vec4f(0.12, 0.12, 0.15, 1.0),
    padding=8.0f0,
    corner_radius=4.0f0,
    border_color=Vec4f(0.2, 0.2, 0.2, 1.0),
    border_width=1.0f0
)

const MAIN_CONTAINER_STYLE = ContainerStyle(
    background_color=DARK_BG,
    padding=0.0f0
)

# User-managed interaction states for each button
button1_state = Ref(Fugl.InteractionState())
button2_state = Ref(Fugl.InteractionState())
button3_state = Ref(Fugl.InteractionState())
button4_state = Ref(Fugl.InteractionState())
button5_state = Ref(Fugl.InteractionState())
button6_state = Ref(Fugl.InteractionState())

function HoverDemo()
    # Create buttons with different hover styles and user-managed state
    normal_button = TextButton("Hover + Press",
        container_style=DEFAULT_STYLE,
        hover_style=DEFAULT_HOVER_STYLE,
        pressed_style=DEFAULT_PRESSED_STYLE,
        text_style=BUTTON_TEXT_STYLE,
        interaction_state=button1_state[],
        on_interaction_state_change=(new_state) -> button1_state[] = new_state
    )

    hover_only_button = TextButton("Hover Only",
        container_style=DEFAULT_STYLE,
        hover_style=DEFAULT_HOVER_STYLE,
        text_style=BUTTON_TEXT_STYLE,
        interaction_state=button2_state[],
        on_interaction_state_change=(new_state) -> button2_state[] = new_state
    )

    pressed_only_button = TextButton("Press Only",
        container_style=DEFAULT_STYLE,
        pressed_style=DEFAULT_PRESSED_STYLE,
        text_style=BUTTON_TEXT_STYLE,
        interaction_state=button3_state[],
        on_interaction_state_change=(new_state) -> button3_state[] = new_state
    )

    disabled_effects_button = TextButton("No Effects",
        container_style=DEFAULT_STYLE,
        text_style=BUTTON_TEXT_STYLE
        # Note: No interaction_state - this one doesn't have interactive styling
    )

    # Button with on_mouse_down callback
    mouse_down_button = TextButton("Mouse Down Demo",
        container_style=DEFAULT_STYLE,
        hover_style=DEFAULT_HOVER_STYLE,
        pressed_style=DEFAULT_PRESSED_STYLE,
        text_style=BUTTON_TEXT_STYLE,
        interaction_state=button5_state[],
        on_interaction_state_change=(new_state) -> button5_state[] = new_state,
        on_click=() -> println("Button clicked!"),
        on_mouse_down=() -> println("Mouse pressed down on button!")
    )

    custom_button = TextButton("Custom Blue/Red",
        container_style=CUSTOM_STYLE,
        hover_style=CUSTOM_HOVER_STYLE,
        pressed_style=CUSTOM_PRESSED_STYLE,
        text_style=CUSTOM_TEXT_STYLE,
        interaction_state=button6_state[],
        on_interaction_state_change=(new_state) -> button6_state[] = new_state,
        on_mouse_down=() -> println("Custom button mouse down!")
    )

    # Dark container with all elements
    Container(
        Column([
                Fugl.Text("Hover & Press Demo - Try hovering and clicking buttons",
                    style=TITLE_TEXT_STYLE
                ),
                normal_button,
                hover_only_button,
                pressed_only_button,
                disabled_effects_button,
                mouse_down_button,
                custom_button,
                Fugl.Text("Check console for mouse down messages",
                    style=INFO_TEXT_STYLE
                ),
                Container(
                    Fugl.Text("Pressed style shows immediately, hover on mouse over",
                        style=HELP_TEXT_STYLE
                    ),
                    style=INFO_CONTAINER_STYLE
                )
            ], spacing=12.0f0, padding=20.0f0),
        style=MAIN_CONTAINER_STYLE
    )
end

# Run the hover demo
Fugl.run(HoverDemo, title="Dark Mode Hover Demo", window_width_px=650, window_height_px=500, fps_overlay=true)