using Fugl

# Dark mode button styles for fixed-size buttons
const BUTTON_STYLE = ContainerStyle(
    background_color=Vec4f(0.08, 0.10, 0.14, 1.0f0),
    border_color=Vec4f(0.15, 0.18, 0.25, 1.0f0),
    border_width=1.5f0,
    padding=4.0f0,  # Reduced padding for smaller buttons
    corner_radius=4.0f0,
    anti_aliasing_width=1.0f0
)

const BUTTON_HOVER_STYLE = ContainerStyle(
    background_color=Vec4f(0.12, 0.14, 0.18, 1.0f0),
    border_color=Vec4f(0.20, 0.23, 0.30, 1.0f0),
    border_width=2.0f0,
    padding=4.0f0,
    corner_radius=4.0f0,
    anti_aliasing_width=1.0f0
)

const BUTTON_PRESSED_STYLE = ContainerStyle(
    background_color=Vec4f(0.06, 0.08, 0.12, 1.0f0),
    border_color=Vec4f(0.10, 0.45, 0.20, 1.0f0),
    border_width=2.0f0,
    padding=4.0f0,
    corner_radius=4.0f0,
    anti_aliasing_width=1.0f0
)

# Text style optimized for small buttons
const INTERACTION_STATE_BUTTON_TEXT_STYLE = TextStyle(
    size_points=11,  # Smaller text for 40x40 buttons
    color=Vec4f(0.9, 0.9, 0.95, 1.0)
)

# Dark mode card style
const DARK_CARD_STYLE = ContainerStyle(
    background_color=Vec4f(0.15, 0.15, 0.18, 1.0),
    border_color=Vec4f(0.25, 0.25, 0.30, 1.0),
    border_width=1.5f0,
    padding=16.0f0,
    corner_radius=6.0f0,
    anti_aliasing_width=1.0f0
)

const DARK_TITLE_STYLE = TextStyle(
    size_points=18,
    color=Vec4f(0.9, 0.9, 0.95, 1.0)
)

# Button interaction states for all buttons
button_states = [Ref(InteractionState()) for _ in 1:12]

function fixed_size_button(label::String, index::Int, on_click::Function)
    button = FixedSize(
        TextButton(
            label,
            on_click=on_click,
            text_style=INTERACTION_STATE_BUTTON_TEXT_STYLE,
            container_style=BUTTON_STYLE,
            pressed_style=BUTTON_PRESSED_STYLE,
            hover_style=BUTTON_HOVER_STYLE,
            interaction_state=button_states[index][],
            on_interaction_state_change=(new_state) -> button_states[index][] = new_state
        ),
        40, 40
    )
    return button
end

function test_fixed_size_buttons()
    function MyApp()
        Card(
            "Fixed Size Button Demo (40x40)",
            IntrinsicColumn([
                    # Row 1: Numbers
                    IntrinsicRow([
                            fixed_size_button("1", 1, () -> println("Button 1 clicked!")),
                            fixed_size_button("2", 2, () -> println("Button 2 clicked!")),
                            fixed_size_button("3", 3, () -> println("Button 3 clicked!")),
                            fixed_size_button("4", 4, () -> println("Button 4 clicked!"))
                        ], spacing=8.0f0, reduce_spacing_on_overflow=true),

                    # Row 2: Letters
                    IntrinsicRow([
                            fixed_size_button("A", 5, () -> println("Button A clicked!")),
                            fixed_size_button("B", 6, () -> println("Button B clicked!")),
                            fixed_size_button("C", 7, () -> println("Button C clicked!")),
                            fixed_size_button("D", 8, () -> println("Button D clicked!"))
                        ], spacing=8.0f0, reduce_spacing_on_overflow=true),

                    # Row 3: Symbols
                    IntrinsicRow([
                            fixed_size_button("+", 9, () -> println("Button + clicked!")),
                            fixed_size_button("-", 10, () -> println("Button - clicked!")),
                            fixed_size_button("×", 11, () -> println("Button × clicked!")),
                            fixed_size_button("=", 12, () -> println("Button = clicked!"))
                        ], spacing=8.0f0, reduce_spacing_on_overflow=true)
                ], spacing=12.0f0, reduce_spacing_on_overflow=true),  # Smart spacing reduction for small buttons
            style=DARK_CARD_STYLE,
            title_style=DARK_TITLE_STYLE
        )
    end

    Fugl.run(MyApp, title="Fixed Size Button Demo", window_width_points=400, window_height_points=350)
end

test_fixed_size_buttons()