"""
    TextField(
        state::EditorState=EditorState();
        max_length::Union{Int, Nothing}=nothing,
        style::TextEditorStyle=TextBoxStyle(border_width=1.0f0),
        on_state_change::Function=(new_state::EditorState) -> nothing,
        on_change::Function=(new_text) -> nothing,
        on_focus::Function=() -> nothing,
        on_blur::Function=() -> nothing
    )

Single-line form field for entering text. Supports optional length limiting.

## Arguments
- `state::EditorState`: Initial state of the text box.
- `max_length::Union{Int, Nothing}`: Maximum number of characters allowed (default is `nothing` for unlimited).
- `style::TextEditorStyle`: Style for the text field.
- `on_state_change::Function`: Callback for when the state changes. Must update a state ref or similar.
- `on_change::Function`: Optional callback for when the text changes. Passes the new text string.
- `on_focus::Function`: Optional callback for when the component gains focus.
- `on_blur::Function`: Optional callback for when the component loses focus.
"""
function TextField(
    state::EditorState=EditorState();
    max_length::Union{Int,Nothing}=nothing,
    style::TextEditorStyle=TextBoxStyle(border_width=1.0f0),
    on_state_change::Function=(new_state::EditorState) -> nothing,
    on_change::Function=(new_text) -> nothing,
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

                # Apply length limit if specified
                if max_length !== nothing && length(text) > max_length
                    text = text[1:max_length]
                end

                # Create cleaned state
                cleaned_state = EditorState(new_state; text=text)

                # Check if this is a focus loss (was focused, now not focused)
                focus_lost = state.is_focused && !new_state.is_focused

                # Call on_change only on focus loss to avoid disrupting typing
                if focus_lost
                    on_state_change(cleaned_state)
                    on_change(text)
                else
                    # Just update state without triggering on_change
                    on_state_change(cleaned_state)
                end
            end,
            on_change=(new_text) -> begin
                # Handle Enter key press by removing newlines and applying length limit
                if occursin('\n', new_text)
                    clean_text = replace(new_text, '\n' => "")
                    clean_text = replace(clean_text, '\r' => "")

                    # Apply length limit if specified
                    if max_length !== nothing && length(clean_text) > max_length
                        clean_text = clean_text[1:max_length]
                    end

                    # Update state and trigger change callback on Enter
                    temp_state = EditorState(clean_text)
                    on_state_change(temp_state)
                    on_change(clean_text)
                end
                # Note: We don't call on_change for regular text changes during typing
                # to avoid focus disruption. on_change is only called on focus loss or Enter.
            end
        ), height)
    )
end