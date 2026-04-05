using Fugl

# Demo states for different spinners
spinner_state_1 = Ref(SpinnerState())
spinner_state_2 = Ref(SpinnerState())
spinner_state_3 = Ref(SpinnerState())
spinner_state_4 = Ref(SpinnerState())

# Toggle button states
toggle_button_1_state = Ref(InteractionState())
toggle_button_2_state = Ref(InteractionState())
toggle_button_3_state = Ref(InteractionState())
toggle_button_4_state = Ref(InteractionState())

# Dark theme colors  
const DARK_BG = Vec4f(0.15, 0.15, 0.18, 1.0)
const DARK_TEXT = Vec4f(0.9, 0.9, 0.95, 1.0)
const DARK_ACCENT = Vec4f(0.4, 0.6, 0.9, 1.0)

# Spinner text styles
spinner_style_large = TextStyle(
    size_points=24,
    color=DARK_ACCENT
)

spinner_style_medium = TextStyle(
    size_points=18,
    color=DARK_TEXT
)

label_style = TextStyle(
    size_points=14,
    color=DARK_TEXT
)

container_style = ContainerStyle(
    background_color=DARK_BG,
    padding=20.0f0,
    corner_radius=8.0f0
)

function create_spinner_demo()
    Card("Spinner Demo",
        IntrinsicColumn([

                # Spinner demonstrations
                IntrinsicHeight(
                    IntrinsicColumn([
                            # Default Julia Mono spinner
                            IntrinsicRow([
                                    FixedWidth(
                                        Spinner(
                                            state=spinner_state_1[],
                                            interval_seconds=0.1,
                                            text_style=spinner_style_large,
                                            on_state_change=(new_state) -> spinner_state_1[] = new_state
                                        ),
                                        40.0f0
                                    ),
                                    Fugl.Text("Default Julia Mono Spinner (fast)", style=label_style),
                                    FixedWidth(
                                        TextButton(
                                            spinner_state_1[].is_spinning ? "Stop" : "Start",
                                            on_click=() -> begin
                                                current_state = spinner_state_1[]
                                                new_state = SpinnerState(
                                                    current_state.current_index,
                                                    current_state.last_update_time,
                                                    !current_state.is_spinning
                                                )
                                                spinner_state_1[] = new_state
                                            end,
                                            interaction_state=toggle_button_1_state[],
                                            on_interaction_state_change=(new_state) -> toggle_button_1_state[] = new_state
                                        ),
                                        60.0f0
                                    )
                                ], spacing=10.0f0)

                            # Dots spinner (slower)
                            IntrinsicRow([
                                    FixedWidth(
                                        DotsSpinner(
                                            state=spinner_state_2[],
                                            interval_seconds=0.2,
                                            text_style=spinner_style_large,
                                            on_state_change=(new_state) -> spinner_state_2[] = new_state
                                        ),
                                        40.0f0
                                    ),
                                    Fugl.Text("Dots Spinner (slower)", style=label_style),
                                    FixedWidth(
                                        TextButton(
                                            spinner_state_2[].is_spinning ? "Stop" : "Start",
                                            on_click=() -> begin
                                                current_state = spinner_state_2[]
                                                new_state = SpinnerState(
                                                    current_state.current_index,
                                                    current_state.last_update_time,
                                                    !current_state.is_spinning
                                                )
                                                spinner_state_2[] = new_state
                                            end,
                                            interaction_state=toggle_button_2_state[],
                                            on_interaction_state_change=(new_state) -> toggle_button_2_state[] = new_state
                                        ),
                                        60.0f0
                                    )
                                ], spacing=10.0f0)

                            # Arrows spinner
                            IntrinsicRow([
                                    FixedWidth(
                                        ArrowsSpinner(
                                            state=spinner_state_3[],
                                            interval_seconds=0.15,
                                            text_style=spinner_style_medium,
                                            on_state_change=(new_state) -> spinner_state_3[] = new_state
                                        ),
                                        40.0f0
                                    ),
                                    Fugl.Text("Arrows Spinner", style=label_style),
                                    FixedWidth(
                                        TextButton(
                                            spinner_state_3[].is_spinning ? "Stop" : "Start",
                                            on_click=() -> begin
                                                current_state = spinner_state_3[]
                                                new_state = SpinnerState(
                                                    current_state.current_index,
                                                    current_state.last_update_time,
                                                    !current_state.is_spinning
                                                )
                                                spinner_state_3[] = new_state
                                            end,
                                            interaction_state=toggle_button_3_state[],
                                            on_interaction_state_change=(new_state) -> toggle_button_3_state[] = new_state
                                        ),
                                        60.0f0
                                    )
                                ], spacing=10.0f0)

                            # Bars spinner
                            IntrinsicRow([
                                    FixedWidth(
                                        BarsSpinner(
                                            state=spinner_state_4[],
                                            interval_seconds=0.3,
                                            text_style=spinner_style_medium,
                                            on_state_change=(new_state) -> spinner_state_4[] = new_state
                                        ),
                                        40.0f0
                                    ),
                                    Fugl.Text("Bars Spinner (slow)", style=label_style),
                                    FixedWidth(
                                        TextButton(
                                            spinner_state_4[].is_spinning ? "Stop" : "Start",
                                            on_click=() -> begin
                                                current_state = spinner_state_4[]
                                                new_state = SpinnerState(
                                                    current_state.current_index,
                                                    current_state.last_update_time,
                                                    !current_state.is_spinning
                                                )
                                                spinner_state_4[] = new_state
                                            end,
                                            interaction_state=toggle_button_4_state[],
                                            on_interaction_state_change=(new_state) -> toggle_button_4_state[] = new_state
                                        ),
                                        60.0f0
                                    )
                                ], spacing=10.0f0)
                        ], spacing=15.0f0)
                ),

                # Instructions
                IntrinsicHeight(
                    Fugl.Text("Click Start/Stop buttons to control individual spinners",
                        style=TextStyle(size_points=12, color=Vec4f(0.7, 0.7, 0.7, 1.0)))
                )
            ], spacing=20.0f0),
        style=container_style,
        title_style=TextStyle(size_points=20, color=Vec4f(0.7, 0.7, 0.7, 1.0))
    )
end

function spinner_demo()
    create_spinner_demo()
end

# Run the demo
Fugl.run(spinner_demo,
    title="Spinner Component Demo",
    window_width_points=600,
    window_height_points=400,
    fps_overlay=false
)