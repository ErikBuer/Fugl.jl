using Fugl

function HoverDemo()
    # Create buttons with different hover styles
    normal_button = TextButton("Hover + Press"; enable_hover=true, enable_pressed=true)

    hover_only_button = TextButton("Hover Only"; enable_hover=true, enable_pressed=false)

    pressed_only_button = TextButton("Press Only"; enable_hover=false, enable_pressed=true)

    disabled_effects_button = TextButton("No Effects"; enable_hover=false, enable_pressed=false)

    # Button with on_mouse_down callback
    mouse_down_button = TextButton("Mouse Down Demo";
        enable_hover=true,
        enable_pressed=true,
        on_click=() -> println("Button clicked!"),
        on_mouse_down=() -> println("Mouse pressed down on button!")
    )

    # Custom hover and pressed button
    custom_style = ContainerStyle(
        background_color=Vec4f(0.8, 0.8, 0.8, 1.0),
        border_color=Vec4f(0.5, 0.5, 0.5, 1.0),
        border_width=2.0f0,
        padding=12.0f0,
        corner_radius=8.0f0
    )

    custom_hover_style = ContainerStyle(
        background_color=Vec4f(0.2, 0.6, 0.9, 1.0),  # Blue on hover
        border_color=Vec4f(0.1, 0.4, 0.7, 1.0),      # Darker blue border
        border_width=3.0f0,
        padding=12.0f0,
        corner_radius=8.0f0
    )

    custom_pressed_style = ContainerStyle(
        background_color=Vec4f(0.9, 0.2, 0.2, 1.0),  # Red when pressed
        border_color=Vec4f(0.7, 0.1, 0.1, 1.0),      # Darker red border
        border_width=4.0f0,
        padding=12.0f0,
        corner_radius=8.0f0
    )

    custom_button = Container(
        Fugl.Text("Custom Styles", style=TextStyle(color=Vec4f(1.0, 1.0, 1.0, 1.0))),
        style=custom_style,
        hover_style=custom_hover_style,
        pressed_style=custom_pressed_style,
        on_mouse_down=() -> println("Custom button mouse down!")
    )

    Column([
            Fugl.Text("Hover & Press Demo - Try hovering and clicking buttons"),
            normal_button,
            hover_only_button,
            pressed_only_button,
            disabled_effects_button,
            mouse_down_button,
            custom_button,
            Fugl.Text("Check console for mouse down messages", style=TextStyle(size_px=12)),
            Container(
                Fugl.Text("Pressed style shows immediately, hover on mouse over", style=TextStyle(size_px=10)),
                style=ContainerStyle(padding=5.0f0)
            )
        ], spacing=10.0f0, padding=20.0f0)
end

# Run the hover demo
Fugl.run(HoverDemo, title="Hover Demo", window_width_px=600, window_height_px=400, fps_overlay=true)