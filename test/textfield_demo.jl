using Fugl
using Fugl: Text

function main()
    # Create states for different text fields
    unlimited_text_state = Ref(EditorState("Type anything here..."))
    limited_text_state = Ref(EditorState("Max 20 chars"))
    short_text_state = Ref(EditorState("Max 10"))

    function MyApp()
        Column([
                Fugl.Text("TextField Demo", style=TextStyle(size_px=24)),

                # Unlimited length text field
                Card(
                    "Unlimited Length Text Field",
                    TextField(
                        unlimited_text_state[];
                        on_state_change=(new_state) -> unlimited_text_state[] = new_state,
                        on_change=(new_text) -> println("Unlimited text: '", new_text, "'")
                    )
                ),

                # Limited length text field (20 characters)
                Card(
                    "Limited to 20 characters",
                    TextField(
                        limited_text_state[];
                        max_length=20,
                        on_state_change=(new_state) -> limited_text_state[] = new_state,
                        on_change=(new_text) -> println("Limited text (20): '", new_text, "' (length: ", length(new_text), ")")
                    )
                ),

                # Very short text field (10 characters)
                Card(
                    "Limited to 10 characters",
                    TextField(
                        short_text_state[];
                        max_length=10,
                        on_state_change=(new_state) -> short_text_state[] = new_state,
                        on_change=(new_text) -> println("Short text (10): '", new_text, "' (length: ", length(new_text), ")")
                    )
                ),

                # Display current values
                Card(
                    "Current Values",
                    Column([
                        Fugl.Text("Unlimited: \"" * unlimited_text_state[].text * "\"", style=TextStyle(size_px=14)),
                        Fugl.Text("Limited (20): \"" * limited_text_state[].text * "\" ($(length(limited_text_state[].text)) chars)", style=TextStyle(size_px=14)),
                        Fugl.Text("Short (10): \"" * short_text_state[].text * "\" ($(length(short_text_state[].text)) chars)", style=TextStyle(size_px=14))
                    ])
                )
            ], spacing=20)
    end

    # Run the GUI
    Fugl.run(MyApp, title="TextField Demo", window_width_px=600, window_height_px=500, fps_overlay=true)
end

main()