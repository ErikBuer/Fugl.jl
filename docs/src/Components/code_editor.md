# CodeEditor

``` @example TextBoxExample
using Fugl
using Fugl: Text

# Create editor states for both components
code_editor_state = Ref(EditorState("""function hello_world()
    println("Hello, World!")
    return 42
end"""))

function MyApp()
    IntrinsicColumn([
        IntrinsicHeight(Container(Text("Text Editor Generalization Demo"))),
        # Code Editor Section
        IntrinsicHeight(Container(Text("Code Editor with Syntax Highlighting:"))),
        Container(
            CodeEditor(
                code_editor_state[];
                on_state_change=(new_state) -> code_editor_state[] = new_state,
                on_change=(new_text) -> println("Optional hook. Code is now: ", new_text[1:min(20, length(new_text))], "...")
            )
        ),
    ], padding=0.0, spacing=0.0)
end

screenshot(MyApp, "textBox.png", 840, 400);
nothing #hide
```

![Text Box](textBox.png)
