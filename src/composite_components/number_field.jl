
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
State for NumberField - always contains a valid numeric value.
"""
struct NumberFieldState{T<:Real}
    editor_state::EditorState
    options::NumberFieldOptions{T}
    current_value::T  # Always valid - no Union{Nothing,T}
end

function NumberFieldState(
    initial_value::Union{String,Number}=0.0;
    options::NumberFieldOptions{T}=NumberFieldOptions(Float64)
) where T<:Real
    # Try to cast to target type - force validity
    numeric_value = try
        if initial_value isa String
            isempty(initial_value) ? zero(T) : T(parse(Float64, initial_value))
        else
            T(initial_value)
        end
    catch
        zero(T)  # Default to zero if casting fails
    end

    # Apply constraints
    if options.min_value !== nothing
        numeric_value = max(numeric_value, options.min_value)
    end
    if options.max_value !== nothing
        numeric_value = min(numeric_value, options.max_value)
    end

    # Create editor state with the valid string representation
    display_text = string(numeric_value)
    editor_state = EditorState(display_text)

    return NumberFieldState{T}(editor_state, options, numeric_value)
end



"""
Filter input text to only allow valid numeric characters.
"""
function filter_numeric_input(text::String, options::NumberFieldOptions)::String
    if isempty(text)
        return text
    end

    # Simple filter: remove letters and newlines
    filtered_chars = filter(char -> !isletter(char) && char != '\n', collect(text))

    # Additional validation for floating point and signs
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
        elseif isdigit(char)
            push!(result, char)
        end
    end

    return String(result)
end

"""
Try to update the numeric value through casting.
Returns updated state if successful, original state if casting fails.
"""
function try_update_numeric_value(state::NumberFieldState{T}, new_text::String)::NumberFieldState{T} where T<:Real
    # Handle empty or incomplete input
    if isempty(new_text) || new_text == "-" || new_text == "+"
        # Keep the current value, just update the display text
        new_editor_state = EditorState(state.editor_state, new_text)
        return NumberFieldState{T}(new_editor_state, state.options, state.current_value)
    end

    # Try to cast to target type
    try
        new_value = T(parse(Float64, new_text))

        # Apply constraints
        if state.options.min_value !== nothing && new_value < state.options.min_value
            new_value = state.options.min_value
        end
        if state.options.max_value !== nothing && new_value > state.options.max_value
            new_value = state.options.max_value
        end

        # Update both display text and numeric value
        final_text = string(new_value)
        new_editor_state = EditorState(state.editor_state, final_text)
        return NumberFieldState{T}(new_editor_state, state.options, new_value)

    catch
        # Casting failed - keep original state
        return state
    end
end

"""
Apply editor action with numeric filtering and casting.
"""
function apply_number_editor_action(state::NumberFieldState{T}, action::EditorAction)::NumberFieldState{T} where T<:Real
    # For insert text actions, filter the input
    if action isa InsertText
        # Block letters and newlines immediately
        if any(isletter, action.text) || action.text == "\n"
            return state
        end

        # Filter the text
        filtered_text = filter_numeric_input(action.text, state.options)
        if isempty(filtered_text)
            return state
        end

        # Apply the filtered insertion to get intermediate text
        temp_editor_state = apply_editor_action(state.editor_state, InsertText(filtered_text))
        intermediate_text = temp_editor_state.text

        # Try to update the numeric value
        return try_update_numeric_value(state, intermediate_text)
    else
        # For non-insert actions (cursor movement, deletion), apply directly
        new_editor_state = apply_editor_action(state.editor_state, action)

        # Try to update the numeric value with the new text
        return try_update_numeric_value(state, new_editor_state.text)
    end
end

"""
Style configuration for NumberField appearance.
"""
struct NumberFieldStyle
    text_box_style::TextBoxStyle
end

function NumberFieldStyle(;
    text_box_style::TextBoxStyle=TextBoxStyle()
)
    return NumberFieldStyle(text_box_style)
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
Render the NumberField using TextBox.
"""
function interpret_view(view::NumberFieldView{T}, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}) where T<:Real
    # Create a TextBox with our custom change handler
    text_box = TextBox(
        view.state.editor_state;
        style=view.style.text_box_style,
        on_state_change=(new_editor_state) -> begin
            # Try to update numeric value through casting
            new_number_state = try_update_numeric_value(view.state, new_editor_state.text)

            # Update the editor state (focus, cursor position, etc.)
            final_state = NumberFieldState{T}(
                EditorState(new_number_state.editor_state;
                    is_focused=new_editor_state.is_focused,
                    cursor=new_editor_state.cursor),
                new_number_state.options,
                new_number_state.current_value
            )

            view.on_state_change(final_state)
        end,
        on_change=(new_text) -> begin
            view.on_change(new_text)
        end
    )

    # Delegate rendering to the TextBox
    interpret_view(text_box, x, y, width, height, projection_matrix)
end

"""
Handle click detection for NumberField.
"""
function detect_click(view::NumberFieldView{T}, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32) where T<:Real
    if view.state.editor_state.is_focused
        handle_number_key_input(view, mouse_state)
    end

    if !(mouse_state.button_state[LeftButton] == IsPressed)
        return
    end

    if inside_component(view, x, y, width, height, mouse_state.x, mouse_state.y)
        if !view.state.editor_state.is_focused
            new_editor_state = EditorState(view.state.editor_state; is_focused=true)
            new_number_state = NumberFieldState{T}(
                new_editor_state,
                view.state.options,
                view.state.current_value
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
            view.state.current_value
        )
        view.on_state_change(new_number_state)
    end
end

"""
Handle key input for NumberField with casting-based validation.
"""
function handle_number_key_input(view::NumberFieldView{T}, mouse_state::InputState) where T<:Real
    if !view.state.editor_state.is_focused
        return
    end

    text_changed = false
    cursor_changed = false
    current_state = view.state

    # Handle special key events (arrow keys, delete, etc.)
    for key_event in mouse_state.key_events
        if Int(key_event.action) == Int(GLFW.PRESS) || Int(key_event.action) == Int(GLFW.REPEAT)
            action = key_event_to_action(key_event)
            if action !== nothing
                old_cursor = current_state.editor_state.cursor
                old_text = current_state.editor_state.text

                current_state = apply_number_editor_action(current_state, action)

                if action isa InsertText || action isa DeleteText
                    text_changed = true
                end

                if current_state.editor_state.cursor != old_cursor
                    cursor_changed = true
                end
            end
        end
    end

    # Handle regular character input
    for key in mouse_state.key_buffer
        if key != '\n' && key != '\t' && key != '\b'
            if !isletter(key)
                action = InsertText(string(key))
                current_state = apply_number_editor_action(current_state, action)
                text_changed = true
                cursor_changed = true
            end
        end
    end

    # Trigger callbacks
    if text_changed || cursor_changed
        view.on_state_change(current_state)
        if text_changed
            view.on_change(current_state.editor_state.text)
        end
    end
end


