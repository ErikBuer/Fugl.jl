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
Struct representing the current state of modifier keys.
This provides a clean, explicit API that doesn't require knowledge of GLFW constants.

- `shift`: Whether Shift key is pressed
- `control`: Whether Control key is pressed  
- `alt`: Whether Alt key is pressed
- `super`: Whether Super/Cmd/Windows key is pressed
- `caps_lock`: Whether Caps Lock is active
- `num_lock`: Whether Num Lock is active
"""
struct ModifierKeys
    shift::Bool
    control::Bool
    alt::Bool
    super::Bool
    caps_lock::Bool
    num_lock::Bool
end

"""
Default constructor for ModifierKeys with all keys released
"""
function ModifierKeys()
    return ModifierKeys(false, false, false, false, false, false)
end

"""
Create ModifierKeys from GLFW modifier bit flags
"""
function ModifierKeys(glfw_mods::Int32)
    return ModifierKeys(
        (glfw_mods & GLFW.MOD_SHIFT) != 0,
        (glfw_mods & GLFW.MOD_CONTROL) != 0,
        (glfw_mods & GLFW.MOD_ALT) != 0,
        (glfw_mods & GLFW.MOD_SUPER) != 0,
        false,  # caps_lock - not available in this GLFW version
        false   # num_lock - not available in this GLFW version
    )
end

"""
Check if Control or Command (Super) key is pressed - common pattern for shortcuts
"""
function is_command_key(mods::ModifierKeys)::Bool
    return mods.control || mods.super
end

"""
Check if any modifier key is pressed
"""
function has_any_modifier(mods::ModifierKeys)::Bool
    return mods.shift || mods.control || mods.alt || mods.super
end

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
    # Mouse drag tracking (per button)
    drag_start_position::Dict{MouseButton,Union{Tuple{Float64,Float64},Nothing}}  # Where drag started for each button
    is_dragging::Dict{MouseButton,Bool}          # Whether currently dragging for each button
    last_drag_position::Dict{MouseButton,Union{Tuple{Float64,Float64},Nothing}}   # Last position during drag for incremental movement
    # Double-click tracking
    double_click_threshold::Float64              # Max time between clicks for double-click (seconds)
    was_double_clicked::Dict{MouseButton,Bool}   # Tracks if the button was double-clicked
    # Scroll wheel tracking
    scroll_x::Float64                            # Horizontal scroll delta
    scroll_y::Float64                            # Vertical scroll delta
    # Modifier keys tracking
    modifier_keys::ModifierKeys                  # Current modifier keys state
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
        KeyEvent[], # Initialize empty key events buffer
        Dict(LeftButton => nothing, RightButton => nothing, MiddleButton => nothing),    # No drag start positions initially
        Dict(LeftButton => false, RightButton => false, MiddleButton => false),         # Not dragging initially
        Dict(LeftButton => nothing, RightButton => nothing, MiddleButton => nothing),    # No last drag positions initially
        0.5,        # 500ms double-click threshold
        Dict(LeftButton => false, RightButton => false, MiddleButton => false),  # No double-clicks initially
        0.0,        # No horizontal scroll initially
        0.0,        # No vertical scroll initially
        ModifierKeys()  # No modifier keys initially
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

    current_time = time()
    current_pos = (mouse_state.x, mouse_state.y)

    if action == GLFW.PRESS
        mouse_state.button_state[mapped_button] = IsPressed

        # Start potential drag for this button
        mouse_state.drag_start_position[mapped_button] = current_pos
        mouse_state.is_dragging[mapped_button] = false  # Not dragging yet, just pressed
        mouse_state.last_drag_position[mapped_button] = nothing  # Reset last drag position

    elseif action == GLFW.RELEASE
        mouse_state.button_state[mapped_button] = IsReleased

        # Check for double-click
        time_since_last_click = current_time - mouse_state.last_click_time
        distance_from_last_click = sqrt((current_pos[1] - mouse_state.last_click_position[1])^2 +
                                        (current_pos[2] - mouse_state.last_click_position[2])^2)

        if (time_since_last_click <= mouse_state.double_click_threshold &&
            distance_from_last_click <= 5.0)  # 5 pixel tolerance
            mouse_state.was_double_clicked[mapped_button] = true
        else
            mouse_state.was_clicked[mapped_button] = true
        end

        # Update last click info
        mouse_state.last_click_time = current_time
        mouse_state.last_click_position = current_pos

        # End drag for this button
        mouse_state.drag_start_position[mapped_button] = nothing
        mouse_state.is_dragging[mapped_button] = false
        mouse_state.last_drag_position[mapped_button] = nothing  # Reset last drag position
    end
end

"""
Mouse position callback to track mouse movement and detect dragging
"""
function mouse_position_callback(gl_window, x_pos, y_pos, mouse_state::InputState)
    current_pos = (x_pos, y_pos)

    # For dragging buttons, update last_drag_position to the PREVIOUS position before updating current
    for button in [LeftButton, RightButton, MiddleButton]
        if mouse_state.is_dragging[button]
            # Store the current position as the "last" position before we update to the new position
            mouse_state.last_drag_position[button] = (mouse_state.x, mouse_state.y)
        end
    end

    # Now update current position
    mouse_state.x = x_pos
    mouse_state.y = y_pos

    # Check if we should start dragging for any pressed button
    for button in [LeftButton, RightButton, MiddleButton]
        if (mouse_state.button_state[button] == IsPressed &&
            mouse_state.drag_start_position[button] !== nothing &&
            !mouse_state.is_dragging[button])

            # Check if we should start dragging
            start_pos = mouse_state.drag_start_position[button]
            distance = sqrt((x_pos - start_pos[1])^2 + (y_pos - start_pos[2])^2)

            # Start dragging if moved more than threshold
            if distance > 3.0  # 3 pixel threshold
                mouse_state.is_dragging[button] = true
                # Set initial last_drag_position when dragging starts (use drag start position)
                mouse_state.last_drag_position[button] = start_pos
            end
        end
    end
end

"""
Mouse scroll callback to track scroll wheel input
"""
function scroll_callback(gl_window, xoffset, yoffset, mouse_state::InputState)
    mouse_state.scroll_x = xoffset
    mouse_state.scroll_y = yoffset
end

function key_callback(gl_window, key::GLFW.Key, scancode::Int32, action::GLFW.Action, mods::Int32, mouse_state::InputState)
    # Update modifier keys state using the ModifierKeys constructor
    mouse_state.modifier_keys = ModifierKeys(mods)

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
    elseif action == GLFW.RELEASE
        # Update modifier keys on release too
        mouse_state.modifier_keys = ModifierKeys(mods)
    end
end

"""
New character callback for proper text input
This function handles character input from the keyboard, converting Unicode codepoints to characters.
"""
function char_callback(gl_window, codepoint, mouse_state::InputState)
    # Drop input if buffer is too large
    if length(mouse_state.key_buffer) >= 50  # Reasonable limit
        return  # Silently drop excess input
    end
    push!(mouse_state.key_buffer, Char(codepoint))
end

"""
Alternative signature in case GLFW passes Char directly
This function adds a character directly to the key buffer.
"""
function key_callback(gl_window, key, scancode, action, mods, mouse_state::InputState)
    # Drop input if buffer is too large  
    if length(mouse_state.key_events) >= 50  # Reasonable limit
        return  # Silently drop excess input
    end
    push!(mouse_state.key_events, KeyEvent(key, scancode, action, mods))
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
        deepcopy(mouse_state.drag_start_position),
        deepcopy(mouse_state.is_dragging),
        deepcopy(mouse_state.last_drag_position),
        mouse_state.double_click_threshold,
        deepcopy(mouse_state.was_double_clicked),
        mouse_state.scroll_x,
        mouse_state.scroll_y,
        mouse_state.modifier_keys
    )

    # Reset `was_clicked`, `was_double_clicked`, and scroll in the original state
    for button in keys(mouse_state.was_clicked)
        mouse_state.was_clicked[button] = false
        mouse_state.was_double_clicked[button] = false
    end

    # Reset scroll values
    mouse_state.scroll_x = 0.0
    mouse_state.scroll_y = 0.0

    return locked_state
end