# Simple KeyListener example showing keyboard shortcuts

using Fugl
using GLFW

message = Ref("Press 'A', 'S', or 'Enter' for different actions")
counter = Ref(0)

function MyApp()
    # Create a simple container with text
    content = Container(
        Column([
            Fugl.Text(message[], style=TextStyle(size_px=16)),
            Fugl.Text("Counter: $(counter[])", style=TextStyle(size_px=14, color=Vec4f(0.7, 0.7, 0.7, 1.0)))
        ]),
        style=ContainerStyle(padding=20.0f0)
    )

    # Add keyboard shortcuts to the content
    with_shortcuts = KeyListener(
        content,
        GLFW.KEY_A,
        () -> begin
            message[] = "You pressed 'A'!"
            counter[] += 1
        end
    )

    with_save_shortcut = KeyListener(
        with_shortcuts,
        GLFW.KEY_S,
        GLFW.MOD_CONTROL,  # Ctrl+S
        () -> begin
            message[] = "You pressed 'Ctrl+S' (Save shortcut)!"
            counter[] += 5
        end
    )

    with_enter_shortcut = KeyListener(
        with_save_shortcut,
        GLFW.KEY_ENTER,
        () -> begin
            message[] = "You pressed 'Enter'!"
            counter[] = 0  # Reset counter
        end
    )

    return with_enter_shortcut
end

println("Starting KeyListener Demo...")
println("Try pressing:")
println("  - A: Increment counter")
println("  - Ctrl+S: Add 5 to counter")
println("  - Enter: Reset counter")

Fugl.run(MyApp, title="KeyListener Demo - Keyboard Shortcuts", window_width_px=500, window_height_px=200)
