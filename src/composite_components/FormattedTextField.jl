"""
    FormattedTextField(
        state::EditorState=EditorState();
        max_length::Union{Int, Nothing}=nothing,
        parser::Union{Function, Nothing}=nothing,
        validator::Union{Function, Nothing}=nothing,
        style::TextEditorStyle=TextBoxStyle(border_width=1.0f0),
        on_state_change::Function=(new_state::EditorState) -> nothing,
        on_change::Function=(parsed_value) -> nothing,
        on_focus::Function=() -> nothing,
        on_blur::Function=() -> nothing
    )

Single-line form field with custom formatting, validation, and parsing.

## Arguments
- `state::EditorState`: Initial state of the text box.
- `max_length::Union{Int, Nothing}`: Maximum number of characters allowed (default is `nothing` for unlimited).
- `parser::Union{Function, Nothing}`: Function that takes text and returns `(cleaned_text::String, parsed_value)`. Applied on focus loss and Enter.
- `validator::Union{Function, Nothing}`: Function that filters input during typing. Takes text, returns filtered text.
- `style::TextEditorStyle`: Style for the text field.
- `on_state_change::Function`: Callback for when the state changes. Must update a state ref or similar.
- `on_change::Function`: Optional callback for when parsing succeeds. Receives the parsed value.
- `on_focus::Function`: Optional callback for when the component gains focus.
- `on_blur::Function`: Optional callback for when the component loses focus.

## Example: Hex Color Field
```julia
hex_parser(text) = begin
    # Remove # prefix if present, ensure uppercase
    clean = uppercase(replace(text, "#" => ""))
    # Validate hex format
    if match(r"^[0-9A-F]{6}\$", clean) !== nothing
        return ("#" * clean, clean)
    else
        return ("#000000", "000000")  # Default to black
    end
end

hex_validator(text) = begin
    # Allow only valid hex characters and #
    replace(uppercase(text), r"[^#0-9A-F]" => "")
end

FormattedTextField(
    state,
    parser=hex_parser,
    validator=hex_validator,
    on_change=(hex_value) -> println("Valid hex: ", hex_value)
)
```
"""
function FormattedTextField(
    state::EditorState=EditorState();
    max_length::Union{Int,Nothing}=nothing,
    parser::Union{Function,Nothing}=nothing,
    validator::Union{Function,Nothing}=nothing,
    style::TextEditorStyle=TextBoxStyle(border_width=1.0f0),
    on_state_change::Function=(new_state::EditorState) -> nothing,
    on_change::Function=(parsed_value) -> nothing,
    on_focus::Function=() -> nothing,
    on_blur::Function=() -> nothing
)
    height = style.text_style.size_px + 2 * style.padding + 1

    return (
        FixedHeight(
        TextBox(
            state,
            style=style,
            on_focus=on_focus,
            on_blur=on_blur,
            on_state_change=(new_state) -> begin
                text = new_state.text

                # Remove newlines to keep it single-line
                text = replace(text, '\n' => "")
                text = replace(text, '\r' => "")

                # Apply validator during typing if provided
                if validator !== nothing
                    text = validator(text)
                end

                # Apply length limit if specified
                if max_length !== nothing && length(text) > max_length
                    text = text[1:max_length]
                end

                # Create cleaned state
                cleaned_state = EditorState(new_state; text=text)

                # Check if this is a focus loss (was focused, now not focused)
                focus_lost = state.is_focused && !new_state.is_focused

                # Apply parser on focus loss
                if focus_lost && parser !== nothing
                    try
                        (parsed_text, parsed_value) = parser(text)
                        final_state = EditorState(cleaned_state; text=parsed_text)
                        on_state_change(final_state)
                        on_change(parsed_value)
                    catch e
                        # Parser failed, just update state without calling on_change
                        on_state_change(cleaned_state)
                    end
                else
                    # Just update state without parsing
                    on_state_change(cleaned_state)
                end
            end,
            on_change=(new_text) -> begin
                # Handle Enter key press
                if occursin('\n', new_text)
                    clean_text = replace(new_text, '\n' => "")
                    clean_text = replace(clean_text, '\r' => "")

                    # Apply validator if provided
                    if validator !== nothing
                        clean_text = validator(clean_text)
                    end

                    # Apply length limit if specified
                    if max_length !== nothing && length(clean_text) > max_length
                        clean_text = clean_text[1:max_length]
                    end

                    # Apply parser on Enter if provided
                    if parser !== nothing
                        try
                            (parsed_text, parsed_value) = parser(clean_text)
                            final_state = EditorState(parsed_text)
                            on_state_change(final_state)
                            on_change(parsed_value)
                        catch e
                            # Parser failed, use cleaned text
                            temp_state = EditorState(clean_text)
                            on_state_change(temp_state)
                        end
                    else
                        # No parser, just use cleaned text
                        temp_state = EditorState(clean_text)
                        on_state_change(temp_state)
                        on_change(clean_text)
                    end
                end
            end
        ), height)
    )
end