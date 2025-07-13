using Fugl
using Fugl: Text

function main()
    # Create editor states for both components
    code_editor_state = Ref(EditorState("""function hello_world()
    println("Hello, World!")
    return 42
end"""))

    text_box_state = Ref(EditorState("Enter your text here..."))

    function MyApp()
        IntrinsicColumn([
            IntrinsicHeight(Container(Text("Text Editor Generalization Demo"))),

            # Code Editor Section
            IntrinsicHeight(Container(Text("Code Editor with Syntax Highlighting:"))),
            Container(
                CodeEditor(
                    code_editor_state[];
                    on_change=(text) -> begin
                        code_editor_state[] = EditorState(code_editor_state[], text)
                    end,
                    on_focus_change=(focused) -> begin
                        code_editor_state[] = EditorState(code_editor_state[]; is_focused=focused)
                    end
                )
            ),

            # Text Box Section
            IntrinsicHeight(Container(Text("Plain Text Box:"))),
            Container(
                TextBox(
                    text_box_state[];
                    on_change=(text) -> text_box_state[] = EditorState(text_box_state[], text),
                    on_focus_change=(focused) -> text_box_state[] = EditorState(text_box_state[]; is_focused=focused)
                )
            ),
        ])
    end

    # Run the GUI
    Fugl.run(MyApp, title="Text Editor Generalization Demo", window_width_px=600, window_height_px=400)
end

main()
