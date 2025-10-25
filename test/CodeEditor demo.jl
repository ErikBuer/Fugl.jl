using Fugl
using Fugl: Text

# Create editor states for both components
code_editor_state = Ref(EditorState("""function hello_world()
    println("Hello, World!")
    return 42
end"""))

# Dark theme card style
dark_card_style = ContainerStyle(
    background_color=Vec4f(0.15, 0.15, 0.18, 1.0),  # Dark background
    border_color=Vec4f(0.25, 0.25, 0.30, 1.0),      # Subtle border
    border_width=1.5f0,
    padding=12.0f0,
    corner_radius=6.0f0,
    anti_aliasing_width=1.0f0
)

# Dark theme title style
dark_title_style = TextStyle(
    size_px=18,
    color=Vec4f(0.9, 0.9, 0.95, 1.0)  # Light text for titles
)

function MyApp()
    Card(
        "Code Editor with Syntax Highlighting:",
        CodeEditor(
            code_editor_state[];
            on_state_change=(new_state) -> code_editor_state[] = new_state,
            on_change=(new_text) -> println("Optional hook. Code is now: ", new_text[1:min(20, length(new_text))], "...")
        ),
        style=dark_card_style,
        title_style=dark_title_style
    )
end

# Run the scroll area demo
Fugl.run(MyApp,
    title="CodeEditor",
    window_width_px=700,
    window_height_px=500,
    fps_overlay=true
)
