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

"""
Struct representing a keyboard event.

- `key`: GLFW key code (e.g., GLFW.KEY_A, GLFW.KEY_ENTER)
- `scancode`: Hardware-specific scancode
- `action`: GLFW action (GLFW.PRESS, GLFW.RELEASE, GLFW.REPEAT)
- `mods`: Modifier key flags (GLFW.MOD_SHIFT, GLFW.MOD_CONTROL, etc.)
"""
struct KeyEvent
    key::Int32
    scancode::Int32
    action::Int32
    mods::Int32
end

mutable struct InputState
    button_state::Dict{MouseButton,ButtonState}  # Current button state
    was_clicked::Dict{MouseButton,Bool}          # Tracks if the button was clicked
    x::Float64                                   # Current mouse X position
    y::Float64                                   # Current mouse Y position
    last_click_time::Float64                     # Time of the last click
    last_click_position::Tuple{Float64,Float64}  # Position of the last click
    key_buffer::Vector{Char}                     # Buffer for character input
    key_events::Vector{KeyEvent}                 # Buffer for key events
end

function InputState()
    return InputState(
        Dict(LeftButton => IsReleased, RightButton => IsReleased, MiddleButton => IsReleased),
        Dict(LeftButton => false, RightButton => false, MiddleButton => false),
        0.0,
        0.0,
        0.0,
        (0.0, 0.0),
        Char[],     # Initialize an empty key buffer
        KeyEvent[]  # Initialize empty key events buffer
    )
end

function mouse_button_callback(gl_window, button, action, mods, mouse_state::InputState)
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

function key_callback(gl_window, key::GLFW.Key, scancode::Int32, action::GLFW.Action, mods::Int32, mouse_state::InputState)
    if action == GLFW.PRESS || action == GLFW.REPEAT
        # Store raw key events for navigation and shortcuts
        key_event = KeyEvent(Int32(key), scancode, Int32(action), mods)
        push!(mouse_state.key_events, key_event)

        # Handle special keys that produce characters
        if key == GLFW.KEY_ENTER
            push!(mouse_state.key_buffer, '\n')
        elseif key == GLFW.KEY_BACKSPACE
            push!(mouse_state.key_buffer, '\b')
        elseif key == GLFW.KEY_TAB
            push!(mouse_state.key_buffer, '\t')
        end
    end
end

"""
New character callback for proper text input
This function handles character input from the keyboard, converting Unicode codepoints to characters.
"""
function char_callback(gl_window, codepoint::UInt32, mouse_state::InputState)
    # Convert Unicode codepoint to character and add to buffer
    char = Char(codepoint)
    push!(mouse_state.key_buffer, char)
end

"""
Alternative signature in case GLFW passes Char directly
This function adds a character directly to the key buffer.
"""
function char_callback(gl_window, char::Char, mouse_state::InputState)
    # Add character directly to buffer
    push!(mouse_state.key_buffer, char)
end

function collect_state!(mouse_state::InputState)::InputState
    # Create a copy of the InputState
    locked_state = InputState(
        deepcopy(mouse_state.button_state),
        deepcopy(mouse_state.was_clicked),
        mouse_state.x,
        mouse_state.y,
        mouse_state.last_click_time,
        mouse_state.last_click_position,
        deepcopy(mouse_state.key_buffer),
        deepcopy(mouse_state.key_events),
    )

    # Reset `was_clicked` in the original state
    for button in keys(mouse_state.was_clicked)
        mouse_state.was_clicked[button] = false
    end

    return locked_state
end