# CodeEditor

``` @example TextBoxExample
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

screenshot(MyApp, "CodeEditor.png", 812, 400);
nothing #hide
```

![Code Editor](CodeEditor.png)

## Focus and Blur Events

``` @example FocusBlurCodeEditorExample
using Fugl

focus_status = Ref("Click the code editor below")
code_editor_state = Ref(EditorState("""# Click here to focus
print("Hello World!")"""))

function MyApp()
    Card(
        focus_status[],
        CodeEditor(
            code_editor_state[];
            on_state_change=(new_state) -> code_editor_state[] = new_state,
            on_focus=() -> focus_status[] = "🎯 Code editor is focused - start typing!",
            on_blur=() -> focus_status[] = "💤 Code editor lost focus - click to refocus"
        )
    )
end

screenshot(MyApp, "codeEditorFocusBlur.png", 812, 350);
nothing #hide
```

![CodeEditor Focus/Blur Events](codeEditorFocusBlur.png)
