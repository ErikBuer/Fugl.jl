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
                Card(
                    "Code Editor with Syntax Highlighting:",
                    CodeEditor(
                        code_editor_state[];
                        on_state_change=(new_state) -> code_editor_state[] = new_state,
                        on_change=(new_text) -> println("Code changed to: ", new_text[1:min(20, length(new_text))], "...")
                    )
                ),

                # Text Box Section
                Card(
                    "Plain Text Box",
                    TextBox(
                        text_box_state[];
                        on_state_change=(new_state) -> text_box_state[] = new_state,
                        on_change=(new_text) -> println("Text changed to: ", new_text[1:min(20, length(new_text))], "...")
                    )
                ),
            ],
            spacing=0
        )
    end

    # Run the GUI
    Fugl.run(MyApp, title="Text Editor Generalization Demo", window_width_px=812, window_height_px=600, fps_overlay=true)
end

main()