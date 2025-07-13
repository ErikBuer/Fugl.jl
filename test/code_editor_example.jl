using Fugl
using Fugl: Text, EditorState, CursorPosition

function main()
    # Create editor state with initial code
    editor_state = Ref(EditorState("""function hello_world()
    println("Hello, World!")
    x = 42  # This is a number
    name = "Julia"  # This is a string
    return x + length(name)
end

# Call the function
result = hello_world()"""))

    function MyApp()
        IntrinsicColumn([
            IntrinsicHeight(Container(Text("Julia Code Editor with Cursor"))),
            Container(
                CodeEditor(
                    editor_state[];
                    on_change=(text) -> begin
                        # Create a new editor state with the updated text
                        editor_state[] = EditorState(editor_state[], text)
                    end,
                    on_focus_change=(focused) -> begin
                        editor_state[].is_focused = focused
                    end
                )
            ),
        ])
    end

    # Run the GUI
    Fugl.run(MyApp, title="Julia Code Editor", window_width_px=1000, window_height_px=700)
end

main()
