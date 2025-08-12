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
                # Code Editor Section
                IntrinsicHeight(Container(Text("Code Editor with Syntax Highlighting:"))),
                Container(
                    CodeEditor(
                        code_editor_state[];
                        on_state_change=(new_state) -> code_editor_state[] = new_state,
                        on_change=(new_text) -> println("Code changed to: ", new_text[1:min(20, length(new_text))], "...")
                    )
                ),

                # Text Box Section
                IntrinsicHeight(Container(Text("Plain Text Box:"))),
                Container(
                    TextBox(
                        text_box_state[];
                        on_state_change=(new_state) -> text_box_state[] = new_state,
                        on_change=(new_text) -> println("Text changed to: ", new_text[1:min(20, length(new_text))], "...")
                    )
                ),
            ],
            padding=0, spacing=0
        )
    end

    # Run the GUI
    Fugl.run(MyApp, title="Text Editor Generalization Demo", window_width_px=800, window_height_px=600, fps_overlay=true)
end

main()