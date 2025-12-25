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

function create_number_parser(type::Type)
    return function (text::String)
        try
            parsed_value = smart_parse(type, text)
            return (string(parsed_value), parsed_value)
        catch
            default_value = zero(type)
            return (string(default_value), default_value)
        end
    end
end

function create_number_validator(type::Type)
    return function (text::String)
        # Replace comma with decimal point
        text = replace(text, ',' => '.')
        # Remove all non-numeric characters except for decimal point, sign, and scientific notation
        return replace(text, r"[^0-9\.\-e]" => "")
    end
end

"""
    NumberField(
        state::EditorState=EditorState();
        type::Type=Float64,
        style::TextEditorStyle=TextBoxStyle(border_width=1.0f0),
        on_state_change::Function=(new_state::EditorState) -> nothing,
        on_change::Function=(parsed_value) -> nothing,
        on_focus::Function=() -> nothing,
        on_blur::Function=() -> nothing
    )

Form field for entering numbers. New values are parsed on focus loss.

## Arguments
- `state::EditorState`: Initial state of the text box.
- `type::Type`: The numeric type to parse the input as (default is `Float64`).
- `style::TextEditorStyle`: Style for the text field.
- `on_state_change::Function`: Callback for when the state changes. Must update a state ref or similar.
- `on_change::Function`: Optional callback for when parsing succeeds. Passes the parsed value in specified type.
- `on_focus::Function`: Optional callback for when the component gains focus.
- `on_blur::Function`: Optional callback for when the component loses focus.
"""
function NumberField(
    state::EditorState=EditorState();
    type::Type=Float64,
    style::TextEditorStyle=TextBoxStyle(border_width=1.0f0),
    on_state_change::Function=(new_state::EditorState) -> nothing,
    on_change::Function=(parsed_value) -> nothing,
    on_focus::Function=() -> nothing,
    on_blur::Function=() -> nothing
)
    return FormattedTextField(
        state;
        parser=create_number_parser(type),
        validator=create_number_validator(type),
        style=style,
        on_state_change=on_state_change,
        on_change=on_change,
        on_focus=on_focus,
        on_blur=on_blur
    )
end