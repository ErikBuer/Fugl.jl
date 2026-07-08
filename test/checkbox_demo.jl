using Fugl

# Create checkbox state
checkbox_state = Ref(false)
checkbox_interaction_state = Ref(InteractionState())

style = CheckBoxStyle(
    size=20.0f0,
    background_color=Vec4f(1.0, 1.0, 1.0, 1.0),  # White background
    background_color_checked=Vec4f(0.2, 0.8, 0.2, 1.0),  # Green when checked
    border_color=Vec4f(0.6, 0.6, 0.6, 1.0),  # Gray border
    border_width=1.5f0,
    check_color=Vec4f(1.0, 1.0, 1.0, 1.0),  # White checkmark
    corner_radius=3.0f0,
    padding=2.0f0,
    label_style=TextStyle(size_points=14, color=Vec4f(0.0, 0.0, 0.0, 1.0))
)

hover_style = CheckBoxStyle(
    size=21.0f0,
    background_color=Vec4f(0.95, 0.95, 0.95, 1.0),  # Light gray background
    background_color_checked=Vec4f(0.2, 0.8, 0.2, 1.0),  # Green when checked
    border_color=Vec4f(0.4, 0.4, 0.4, 1.0),  # Darker gray border
    border_width=1.5f0,
    check_color=Vec4f(1.0, 1.0, 1.0, 1.0),  # White checkmark
    corner_radius=3.0f0,
    padding=2.0f0,
    label_style=TextStyle(size_points=14, color=Vec4f(0.0, 0.0, 0.0, 1.0))
)

pressed_style = CheckBoxStyle(
    size=22.0f0,
    background_color=Vec4f(0.9, 0.9, 0.9, 1.0),  # Darker gray background
    background_color_checked=Vec4f(0.2, 0.8, 0.2, 1.0),  # Green when checked
    border_color=Vec4f(0.3, 0.3, 0.3, 1.0),  # Even darker gray border
    border_width=1.5f0,
    check_color=Vec4f(1.0, 1.0, 1.0, 1.0),  # White checkmark
    corner_radius=3.0f0,
    padding=2.0f0,
    label_style=TextStyle(size_points=14, color=Vec4f(0.0, 0.0, 0.0, 1.0))
)

function MyApp()
    Card("CheckBox Demo",
        CheckBox(
            checkbox_state[];
            label="Enable feature",
            style=style,
            hover_style=hover_style,
            pressed_style=pressed_style,
            interaction_state=checkbox_interaction_state[],
            on_interaction_state_change=(s) -> checkbox_interaction_state[] = s,
            on_change=(new_value) -> begin
                checkbox_state[] = new_value
                println("Checkbox is now: $(new_value)")
            end
        )
    )
end

Fugl.run(MyApp, title="CheckBox Test", window_width_points=400, window_height_points=300, fps_overlay=true)
