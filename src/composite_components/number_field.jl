function smart_parse(type::Type, text::String)
    if type <: Integer
        # For integers, truncate at decimal point
        decimal_pos = findfirst('.', text)
        if decimal_pos !== nothing
            text = text[1:decimal_pos-1]  # Remove everything from decimal point onwards
        end
        return parse(type, text)
    else
        # For floats, parse normally
        return parse(type, text)
    end
end

function filter_input(new_state::EditorState, type::Type)
    try
        parsed_value = smart_parse(type, new_state.text)
        return (EditorState(string(parsed_value)), parsed_value)
    catch
        return (EditorState(string(zero(type))), zero(type))
    end
end

"""
    NumberField(
        state::EditorState=EditorState();
        type::Type=Float64,
        on_state_change::Function=(new_state::EditorState) -> nothing,
        on_change::Function=(new_text) -> nothing
    )

Form field for entering numbers. New values are parsed on focus loss.

## Arguments
- `state::EditorState`: Initial state of the text box.
- `type::Type`: The numeric type to parse the input as (default is `Float64`).
- `on_state_change::Function`: Callback for when the state changes. Must update a state ref or similar.
- `on_change::Function`: Optional callback for when the text changes. Passes the new value in specified type.
"""
function NumberField(
    state::EditorState=EditorState();
    type::Type=Float64,
    style::TextBoxStyle=TextBoxStyle(),
    form_height::Float32=Inf32,
    on_state_change::Function=(new_state::EditorState) -> nothing,
    on_change::Function=(new_text) -> nothing
)
    return TextBox(
        state,
        style=style,
        on_state_change=(new_state) -> begin
            text = new_state.text
            text = replace(text, ',' => '.')
            # Remove all non-numeric characters except for decimal point and sign and e.
            text = replace(text, r"[^0-9\.\-e]" => "")
            cleaned_State = EditorState(new_state, text)

            if !(state.is_focused && !new_state.is_focused)
                return on_state_change(cleaned_State)
            end

            (filtered_state, parsed_value) = filter_input(cleaned_State, type)
            on_state_change(filtered_state)
            on_change(parsed_value)
        end,
        on_change=(new_text) -> nothing
    )
end