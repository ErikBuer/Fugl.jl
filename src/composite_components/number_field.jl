
"""
Configuration for a NumberField with type parameter.
"""
struct NumberFieldOptions{T<:Real}
    number_type::Type{T}        # The numeric type (Int, Float64, etc.)
    allow_negative::Bool        # Allow negative numbers
    min_value::Union{Nothing,T}  # Minimum allowed value
    max_value::Union{Nothing,T}  # Maximum allowed value
end

function NumberFieldOptions(::Type{T}=Float64;
    allow_negative::Bool=true,
    min_value::Union{Nothing,T}=nothing,
    max_value::Union{Nothing,T}=nothing
) where T<:Real
    return NumberFieldOptions{T}(T, allow_negative, min_value, max_value)
end

"""
State for NumberField with simplified validation.
"""
struct NumberFieldState{T<:Real}
    editor_state::EditorState
    options::NumberFieldOptions{T}
    current_value::Union{Nothing,T}  # The parsed numeric value
    is_valid::Bool                    # Whether current input is valid
end

function NumberFieldState(
    initial_value::Union{String,Number}="";
    options::NumberFieldOptions{T}=NumberFieldOptions()
) where T<:Real
    # Convert initial value to string for the editor
    display_text = string(initial_value)

    # Try to parse the value
    parsed_value, is_valid = try_parse_and_validate(display_text, options)

    # Create editor state
    editor_state = EditorState(display_text)

    return NumberFieldState{T}(editor_state, options, parsed_value, is_valid)
end

"""
Simple character filter - only allow digits, decimal point, minus sign, and plus sign.
"""
function is_valid_numeric_char(char::Char, options::NumberFieldOptions)::Bool
    # Always allow digits
    if isdigit(char)
        return true
    end

    # Allow decimal point for floating point types
    if char == '.' && (options.number_type <: AbstractFloat)
        return true
    end

    # Allow minus/plus signs if negative numbers are allowed
    if (char == '-' || char == '+') && options.allow_negative
        return true
    end

    return false
end

"""
Filter input text to only allow valid numeric characters.
"""
function filter_numeric_input(text::String, options::NumberFieldOptions)::String
    if isempty(text)
        return text
    end

    # Simple filter: remove any non-numeric characters
    filtered_chars = filter(char -> is_valid_numeric_char(char, options), collect(text))

    # Additional validation: ensure only one decimal point and sign at beginning
    result = Char[]
    has_decimal = false

    for (i, char) in enumerate(filtered_chars)
        if char == '.'
            if !has_decimal && options.number_type <: AbstractFloat
                push!(result, char)
                has_decimal = true
            end
        elseif char == '-' || char == '+'
            # Only allow sign at the beginning
            if i == 1 && options.allow_negative
                push!(result, char)
            end
        else
            # Regular digit
            push!(result, char)
        end
    end

    return String(result)
end

"""
Try to parse and validate the text as the configured numeric type.
"""
function try_parse_and_validate(text::String, options::NumberFieldOptions{T})::Tuple{Union{Nothing,T},Bool} where T<:Real
    if isempty(text) || text == "-" || text == "+"
        return nothing, true  # Empty input is valid
    end

    # Try to parse as the target type
    try
        value = parse(T, text)

        # Check constraints
        if options.min_value !== nothing && value < options.min_value
            return value, false
        end

        if options.max_value !== nothing && value > options.max_value
            return value, false
        end

        return value, true
    catch
        return nothing, false
    end
end

"""
Apply editor action with simplified numeric filtering.
"""
function apply_number_editor_action(state::NumberFieldState{T}, action::EditorAction)::NumberFieldState{T} where T<:Real
    # For insert text actions, filter the input
    if action isa InsertText
        # Remove any letters or invalid characters
        if any(isletter, action.text) || action.text == "\n"  # Block letters and newlines
            return state  # Don't insert anything
        end

        # Filter the text through our numeric filter
        filtered_text = filter_numeric_input(action.text, state.options)

        # If the filtered text is empty, don't insert anything
        if isempty(filtered_text)
            return state
        end

        # Apply the filtered text insertion
        new_editor_state = apply_editor_action(state.editor_state, InsertText(filtered_text))
    else
        # For non-insert actions (cursor movement, deletion), apply directly
        new_editor_state = apply_editor_action(state.editor_state, action)
    end

    # Parse and validate the new text
    new_text = new_editor_state.text
    parsed_value, is_valid = try_parse_and_validate(new_text, state.options)

    return NumberFieldState{T}(new_editor_state, state.options, parsed_value, is_valid)
end

"""
Style configuration for NumberField appearance.
"""
struct NumberFieldStyle
    text_box_style::TextBoxStyle
    invalid_border_color::Vec4{<:AbstractFloat}
    invalid_background_color::Vec4{<:AbstractFloat}
end

function NumberFieldStyle(;
    text_box_style::TextBoxStyle=TextBoxStyle(),
    invalid_border_color::Vec4{<:AbstractFloat}=Vec4{Float32}(1.0f0, 0.2f0, 0.2f0, 1.0f0),  # Red border for invalid
    invalid_background_color::Vec4{<:AbstractFloat}=Vec4{Float32}(1.0f0, 0.95f0, 0.95f0, 1.0f0)  # Light red background for invalid
)
    return NumberFieldStyle(text_box_style, invalid_border_color, invalid_background_color)
end

"""
NumberField view with simplified type handling.
"""
struct NumberFieldView{T<:Real} <: AbstractView
    state::NumberFieldState{T}
    style::NumberFieldStyle
    on_state_change::Function    # Callback for all state changes
    on_change::Function          # Optional callback for text changes only
end

"""
Create a NumberField component.
"""
function NumberField(
    state::NumberFieldState{T};
    style::NumberFieldStyle=NumberFieldStyle(),
    on_state_change::Function=(new_state) -> nothing,
    on_change::Function=(new_text) -> nothing
)::NumberFieldView{T} where T<:Real
    return NumberFieldView{T}(state, style, on_state_change, on_change)
end

"""
Measure the NumberField (delegates to TextBox).
"""
function measure(view::NumberFieldView{T})::Tuple{Float32,Float32} where T<:Real
    # NumberField has the same measurement behavior as TextBox
    return (0.0f0, 0.0f0)
end

"""
Apply layout to NumberField (delegates to TextBox).
"""
function apply_layout(view::NumberFieldView{T}, x::Float32, y::Float32, width::Float32, height::Float32) where T<:Real
    return (x, y, width, height)
end

"""
Render the NumberField using TextBox with validation-aware styling.
"""
function interpret_view(view::NumberFieldView{T}, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}) where T<:Real
    # Create appropriate style based on validation state
    text_box_style = if view.state.is_valid
        view.style.text_box_style
    else
        # Use invalid styling
        TextBoxStyle(
            text_style=view.style.text_box_style.text_style,
            background_color_focused=view.style.invalid_background_color,
            background_color_unfocused=view.style.invalid_background_color,
            border_color=view.style.invalid_border_color,
            border_width_px=view.style.text_box_style.border_width_px,
            corner_radius_px=view.style.text_box_style.corner_radius_px,
            padding_px=view.style.text_box_style.padding_px,
            cursor_color=view.style.text_box_style.cursor_color
        )
    end

    # Create a TextBox with our custom change handler
    text_box = TextBox(
        view.state.editor_state;
        style=text_box_style,
        on_state_change=(new_editor_state) -> begin
            # Parse and validate the new text
            new_text = new_editor_state.text
            parsed_value, is_valid = try_parse_and_validate(new_text, view.state.options)

            new_number_state = NumberFieldState{T}(
                new_editor_state,
                view.state.options,
                parsed_value,
                is_valid
            )
            view.on_state_change(new_number_state)
        end,
        on_change=(new_text) -> begin
            # Call the optional text change callback
            view.on_change(new_text)
        end
    )

    # Delegate rendering to the TextBox
    interpret_view(text_box, x, y, width, height, projection_matrix)
end

"""
Handle click detection for NumberField with simplified numeric input filtering.
"""
function detect_click(view::NumberFieldView{T}, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32) where T<:Real
    if view.state.editor_state.is_focused
        handle_number_key_input(view, mouse_state)  # Handle key input if focused
    end

    if !(mouse_state.button_state[LeftButton] == IsPressed)
        return  # Only handle clicks when the left button is pressed
    end

    if inside_component(view, x, y, width, height, mouse_state.x, mouse_state.y)
        if !view.state.editor_state.is_focused
            new_editor_state = EditorState(view.state.editor_state; is_focused=true)
            new_number_state = NumberFieldState{T}(
                new_editor_state,
                view.state.options,
                view.state.current_value,
                view.state.is_valid
            )
            view.on_state_change(new_number_state)
        end
        return
    end

    if view.state.editor_state.is_focused
        new_editor_state = EditorState(view.state.editor_state; is_focused=false)
        new_number_state = NumberFieldState{T}(
            new_editor_state,
            view.state.options,
            view.state.current_value,
            view.state.is_valid
        )
        view.on_state_change(new_number_state)
    end
end

"""
Handle key input for NumberField with simple letter filtering.
"""
function handle_number_key_input(view::NumberFieldView{T}, mouse_state::InputState) where T<:Real
    if !view.state.editor_state.is_focused
        return  # Only handle key input when the NumberField is focused
    end

    text_changed = false
    cursor_changed = false
    current_state = view.state

    # Handle special key events first (arrow keys, delete, etc.)
    for key_event in mouse_state.key_events
        if Int(key_event.action) == Int(GLFW.PRESS) || Int(key_event.action) == Int(GLFW.REPEAT)
            action = key_event_to_action(key_event)
            if action !== nothing
                old_cursor = current_state.editor_state.cursor
                old_text = current_state.editor_state.text

                # Apply the action with numeric filtering
                current_state = apply_number_editor_action(current_state, action)

                # Check if text changed
                if action isa InsertText || action isa DeleteText
                    text_changed = true
                end

                # Check if cursor changed
                if current_state.editor_state.cursor != old_cursor
                    cursor_changed = true
                end
            end
        end
    end

    # Handle regular character input with simple filtering
    for key in mouse_state.key_buffer
        # Skip special characters that are handled by key events
        if key != '\n' && key != '\t' && key != '\b'  # Skip newline, tab, and backspace
            # Simple check: reject letters, allow numbers and basic symbols
            if !isletter(key)
                old_text = current_state.editor_state.text
                action = InsertText(string(key))
                current_state = apply_number_editor_action(current_state, action)
                text_changed = true
                cursor_changed = true
            end
            # If it's a letter, just ignore it (don't insert)
        end
    end

    # Trigger callbacks if either text or cursor changed
    if text_changed || cursor_changed
        # Always call the state change callback
        view.on_state_change(current_state)

        # Additionally call the text change callback if text actually changed
        if text_changed
            view.on_change(current_state.editor_state.text)
        end
    end
end

"""
Get the numeric value from a NumberFieldState.
Returns the parsed value or nothing if invalid/empty.
"""
function get_numeric_value(state::NumberFieldState{T})::Union{Nothing,T} where T<:Real
    return state.current_value
end

"""
Get the raw text value from a NumberFieldState.
"""
function get_text_value(state::NumberFieldState{T})::String where T<:Real
    return state.editor_state.text
end

"""
Check if the current value in a NumberFieldState is valid.
"""
function is_valid_number(state::NumberFieldState{T})::Bool where T<:Real
    return state.is_valid
end
