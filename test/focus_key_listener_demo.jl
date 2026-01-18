# Focus + KeyListener example showing keyboard shortcuts that require focus

using Fugl

message = Ref("Click the blue area to focus, then press 'A', 'S', or 'Enter'")
counter = Ref(0)
is_focused = Ref(false)

function MyApp()
    # Create a focused content area with visual feedback
    focused_content = Container(
        Column([
                Fugl.Text("Focused Area - Keys Work Here",
                    style=TextStyle(size_px=16, color=Vec4f(1.0, 1.0, 1.0, 1.0))),
                Fugl.Text(message[], style=TextStyle(size_px=14, color=Vec4f(0.9, 0.9, 0.9, 1.0))),
                Fugl.Text("Counter: $(counter[])",
                    style=TextStyle(size_px=14, color=Vec4f(0.8, 0.8, 0.8, 1.0))),
                Fugl.Text("Focused: $(is_focused[])",
                    style=TextStyle(size_px=12, color=is_focused[] ? Vec4f(0.2, 0.8, 0.2, 1.0) : Vec4f(0.8, 0.2, 0.2, 1.0)))
            ], spacing=10.0f0),
        style=ContainerStyle(
            background_color=is_focused[] ? Vec4f(0.2, 0.4, 0.8, 1.0) : Vec4f(0.3, 0.3, 0.3, 1.0),
            border_color=is_focused[] ? Vec4f(0.4, 0.6, 1.0, 1.0) : Vec4f(0.5, 0.5, 0.5, 1.0),
            border_width=is_focused[] ? 3.0f0 : 1.0f0,
            padding=20.0f0,
            corner_radius=8.0f0
        )
    )

    # Add keyboard shortcuts to the focused content
    key_bindings = Tuple{Fugl.GLFW.Key,Union{Nothing,Int32},Function}[
        (Fugl.GLFW.KEY_A, nothing, () -> (message[] = "You pressed 'A'!"; counter[] += 1)),
        (Fugl.GLFW.KEY_S, Fugl.GLFW.MOD_CONTROL, () -> (message[] = "You pressed 'Ctrl+S' (Save shortcut)!"; counter[] += 5)),
        (Fugl.GLFW.KEY_ENTER, nothing, () -> (message[] = "You pressed 'Enter'!"; counter[] = 0))
    ]

    key_listener = KeyListener(focused_content, key_bindings)

    # Wrap with Focus component
    focused_area = Focus(
        key_listener;
        is_focused=is_focused[],
        on_focus_change=(focused) -> begin
            is_focused[] = focused
            if focused
                message[] = "Area focused! Keys now work. Try 'A', 'Ctrl+S', or 'Enter'"
            else
                message[] = "Area unfocused! Click the blue area to focus again"
            end
        end
    )

    # Create unfocus area (empty container)
    unfocus_area = Container(
        Fugl.Text("Click anywhere here to unfocus",
            style=TextStyle(size_px=14, color=Vec4f(0.6, 0.6, 0.6, 1.0))),
        style=ContainerStyle(
            background_color=Vec4f(0.9, 0.9, 0.9, 1.0),
            padding=30.0f0,
            corner_radius=4.0f0
        )
    )

    # Layout everything
    return Column([
            Padding(focused_area, 20.0f0),
            unfocus_area
        ], spacing=20.0f0)
end

println("Starting Focus + KeyListener Demo...")
println("Instructions:")
println("  1. Click the blue area to focus it")
println("  2. When focused, try pressing:")
println("     - A: Increment counter")
println("     - Ctrl+S: Add 5 to counter")
println("     - Enter: Reset counter")
println("  3. Click gray areas to unfocus")

Fugl.run(MyApp, title="Focus + KeyListener Demo", window_width_px=600, window_height_px=400)