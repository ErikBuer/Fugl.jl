"""
Enum representing the different mouse buttons.

- `LeftButton`: The left mouse button.
- `RightButton`: The right mouse button.
- `MiddleButton`: The middle mouse button (scroll button).
"""
@enum MouseButton LeftButton RightButton MiddleButton

"""
Enum representing the state of a mouse button.

- `IsReleased`: The button is currently released.
- `IsPressed`: The button is currently pressed.
"""
@enum ButtonState IsReleased IsPressed

mutable struct MouseState
    button_state::Dict{MouseButton,ButtonState}  # Current button state
    was_clicked::Dict{MouseButton,Bool}         # Tracks if the button was clicked
    x::Float64                                   # Current mouse X position
    y::Float64                                   # Current mouse Y position
    last_click_time::Float64                     # Time of the last click
    last_click_position::Tuple{Float64,Float64} # Position of the last click
    key_buffer::Vector{Char}                     # Buffer for key presses
end

function MouseState()
    return MouseState(
        Dict(LeftButton => IsReleased, RightButton => IsReleased, MiddleButton => IsReleased),
        Dict(LeftButton => false, RightButton => false, MiddleButton => false),
        0.0,
        0.0,
        0.0,
        (0.0, 0.0),
        Char[]  # Initialize an empty key buffer
    )
end

function mouse_button_callback(gl_window, button, action, mods, mouse_state::MouseState)
    mapped_button = if button == GLFW.MOUSE_BUTTON_LEFT
        LeftButton
    elseif button == GLFW.MOUSE_BUTTON_RIGHT
        RightButton
    elseif button == GLFW.MOUSE_BUTTON_MIDDLE
        MiddleButton
    else
        return  # Ignore unsupported buttons
    end

    if action == GLFW.PRESS
        mouse_state.button_state[mapped_button] = IsPressed
    elseif action == GLFW.RELEASE
        mouse_state.button_state[mapped_button] = IsReleased
        mouse_state.was_clicked[mapped_button] = true  # Mark as clicked
    end
end

function key_callback(gl_window, key::GLFW.Key, scancode::Int32, action::GLFW.Action, mods::Int32, mouse_state::MouseState)
    if action == GLFW.PRESS
        # Use GLFW.GetKeyName to get the string representation of the key
        key_name = GLFW.GetKeyName(key, scancode)
        if key_name !== nothing
            for char in key_name
                push!(mouse_state.key_buffer, char)  # Add printable characters to the buffer
            end
        else
            # Handle non-printable keys explicitly
            if key == GLFW.KEY_ENTER
                push!(mouse_state.key_buffer, '\n')  # Add newline for Enter key
            elseif key == GLFW.KEY_BACKSPACE
                push!(mouse_state.key_buffer, '\b')  # Add backspace character
            elseif key == GLFW.KEY_TAB
                push!(mouse_state.key_buffer, '\t')  # Add tab character
            elseif key == GLFW.KEY_ESCAPE
                push!(mouse_state.key_buffer, '\e')  # Add escape character
            end
        end
    end
end

function collect_state!(mouse_state::MouseState)::MouseState
    # Create a copy of the MouseState
    locked_state = MouseState(
        deepcopy(mouse_state.button_state),
        deepcopy(mouse_state.was_clicked),
        mouse_state.x,
        mouse_state.y,
        mouse_state.last_click_time,
        mouse_state.last_click_position,
        deepcopy(mouse_state.key_buffer),
    )

    # Reset `was_clicked` in the original state
    for button in keys(mouse_state.was_clicked)
        mouse_state.was_clicked[button] = false
    end

    return locked_state
end