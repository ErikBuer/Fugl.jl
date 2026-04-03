using Fugl

# Dark mode button styles - Fixed height buttons
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
    size_points=16,
    color=Vec4f(0.9, 0.9, 0.95, 1.0)
)

const LIGHT_TEXT_STYLE = TextStyle(color=Vec4f(0.9, 0.9, 0.95, 1.0))

# Button interaction states
button_states = [Ref(InteractionState()) for _ in 1:12]

function test_spacing_overflow()
    function MyApp()
        IntrinsicRow([
                # Left column: Normal spacing behavior (clips bottom)
                FixedHeight(
                    Card(
                        "Normal Spacing (clips bottom)",
                        IntrinsicColumn([
                                FixedHeight(TextButton("Button 1", container_style=BUTTON_STYLE, hover_style=BUTTON_HOVER_STYLE, text_style=LIGHT_TEXT_STYLE, interaction_state=button_states[1][], on_interaction_state_change=(new_state) -> button_states[1][] = new_state), 50.0f0),
                                FixedHeight(TextButton("Button 2", container_style=BUTTON_STYLE, hover_style=BUTTON_HOVER_STYLE, text_style=LIGHT_TEXT_STYLE, interaction_state=button_states[2][], on_interaction_state_change=(new_state) -> button_states[2][] = new_state), 50.0f0),
                                FixedHeight(TextButton("Button 3", container_style=BUTTON_STYLE, hover_style=BUTTON_HOVER_STYLE, text_style=LIGHT_TEXT_STYLE, interaction_state=button_states[3][], on_interaction_state_change=(new_state) -> button_states[3][] = new_state), 50.0f0),
                                FixedHeight(TextButton("Button 4", container_style=BUTTON_STYLE, hover_style=BUTTON_HOVER_STYLE, text_style=LIGHT_TEXT_STYLE, interaction_state=button_states[4][], on_interaction_state_change=(new_state) -> button_states[4][] = new_state), 50.0f0),
                                FixedHeight(TextButton("Button 5", container_style=BUTTON_STYLE, hover_style=BUTTON_HOVER_STYLE, text_style=LIGHT_TEXT_STYLE, interaction_state=button_states[5][], on_interaction_state_change=(new_state) -> button_states[5][] = new_state), 50.0f0),
                                FixedHeight(TextButton("Button 6", container_style=BUTTON_STYLE, hover_style=BUTTON_HOVER_STYLE, text_style=LIGHT_TEXT_STYLE, interaction_state=button_states[6][], on_interaction_state_change=(new_state) -> button_states[6][] = new_state), 50.0f0)
                            ], spacing=20.0f0, reduce_spacing_on_overflow=false),
                        style=DARK_CARD_STYLE,
                        title_style=DARK_TITLE_STYLE
                    ),
                    400.0f0  # Constrained height - not enough for all buttons with full spacing
                ),

                # Right column: Smart spacing reduction (fits more content)
                FixedHeight(
                    Card(
                        "Smart Spacing (reduces spacing first)",
                        IntrinsicColumn([
                                FixedHeight(TextButton("Button 1", container_style=BUTTON_STYLE, hover_style=BUTTON_HOVER_STYLE, text_style=LIGHT_TEXT_STYLE, interaction_state=button_states[7][], on_interaction_state_change=(new_state) -> button_states[7][] = new_state), 50.0f0),
                                FixedHeight(TextButton("Button 2", container_style=BUTTON_STYLE, hover_style=BUTTON_HOVER_STYLE, text_style=LIGHT_TEXT_STYLE, interaction_state=button_states[8][], on_interaction_state_change=(new_state) -> button_states[8][] = new_state), 50.0f0),
                                FixedHeight(TextButton("Button 3", container_style=BUTTON_STYLE, hover_style=BUTTON_HOVER_STYLE, text_style=LIGHT_TEXT_STYLE, interaction_state=button_states[9][], on_interaction_state_change=(new_state) -> button_states[9][] = new_state), 50.0f0),
                                FixedHeight(TextButton("Button 4", container_style=BUTTON_STYLE, hover_style=BUTTON_HOVER_STYLE, text_style=LIGHT_TEXT_STYLE, interaction_state=button_states[10][], on_interaction_state_change=(new_state) -> button_states[10][] = new_state), 50.0f0),
                                FixedHeight(TextButton("Button 5", container_style=BUTTON_STYLE, hover_style=BUTTON_HOVER_STYLE, text_style=LIGHT_TEXT_STYLE, interaction_state=button_states[11][], on_interaction_state_change=(new_state) -> button_states[11][] = new_state), 50.0f0),
                                FixedHeight(TextButton("Button 6", container_style=BUTTON_STYLE, hover_style=BUTTON_HOVER_STYLE, text_style=LIGHT_TEXT_STYLE, interaction_state=button_states[12][], on_interaction_state_change=(new_state) -> button_states[12][] = new_state), 50.0f0)
                            ], spacing=20.0f0, reduce_spacing_on_overflow=true),  # NEW: Smart spacing reduction!
                        style=DARK_CARD_STYLE,
                        title_style=DARK_TITLE_STYLE
                    ),
                    400.0f0  # Same constrained height
                )
            ], spacing=20.0f0)
    end

    Fugl.run(MyApp, title="Spacing Overflow Demo", window_width_points=1000, window_height_points=700)
end

test_spacing_overflow()