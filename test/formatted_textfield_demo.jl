using Fugl

function main()
    # Hex color field example
    hex_state = Ref(EditorState("#FF0000"))

    # Parser function for hex colors
    function hex_parser(text::String)
        # Remove # prefix if present, ensure uppercase
        clean = uppercase(replace(text, "#" => ""))
        # Validate hex format (6 digits)
        if match(r"^[0-9A-F]{6}$", clean) !== nothing
            return ("#" * clean, clean)
        else
            return ("#000000", "000000")  # Default to black
        end
    end

    # Validator function to filter input during typing
    function hex_validator(text::String)
        # Allow only valid hex characters and #
        filtered = replace(uppercase(text), r"[^#0-9A-F]" => "")
        # Ensure at most one # at the beginning
        if startswith(filtered, "#")
            filtered = "#" * replace(filtered[2:end], "#" => "")
        end
        # Limit to 7 characters (#RRGGBB)
        return filtered[1:min(7, length(filtered))]
    end

    # Number field for comparison
    number_state = Ref(EditorState("42.5"))

    # Plain text field for comparison
    text_state = Ref(EditorState("Hello World"))

    function MyApp()
        IntrinsicColumn([
                Card(
                    "Hex Color Field (FormattedTextField):",
                    FormattedTextField(
                        hex_state[];
                        parser=hex_parser,
                        validator=hex_validator,
                        on_state_change=(new_state) -> hex_state[] = new_state,
                        on_change=(hex_value) -> println("✨ Valid hex color: #", hex_value),
                        on_focus=() -> println("🎨 Hex field gained focus"),
                        on_blur=() -> println("🎨 Hex field lost focus")
                    )
                ), Card(
                    "Number Field (using FormattedTextField):",
                    NumberField(
                        number_state[];
                        type=Float64,
                        on_state_change=(new_state) -> number_state[] = new_state,
                        on_change=(value) -> println("📊 Number parsed: ", value),
                        on_focus=() -> println("🔢 Number field gained focus"),
                        on_blur=() -> println("🔢 Number field lost focus")
                    )
                ), Card(
                    "Plain Text Field:",
                    TextField(
                        text_state[];
                        on_state_change=(new_state) -> text_state[] = new_state,
                        on_change=(text) -> println("📝 Text changed: ", text),
                        on_focus=() -> println("✍️ Text field gained focus"),
                        on_blur=() -> println("✍️ Text field lost focus")
                    )
                ),
            ],
            spacing=0
        )
    end

    # Run the GUI
    Fugl.run(MyApp, title="FormattedTextField Demo", window_width_px=812, window_height_px=600, fps_overlay=true)
end

main()