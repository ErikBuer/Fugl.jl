# Callback System for GLFW
# Designed for JuliaC static compilation compatibility
# Hard-coded callbacks that directly modify InputState - no function storage

# Module-level storage for input state reference
# The callbacks will directly modify this state
const GLOBAL_INPUT_STATE = Ref{Union{Nothing,InputState}}(nothing)

# Function to register the input state - called by parent module
function set_input_state!(input_state)
    GLOBAL_INPUT_STATE[] = input_state
end

# Module-level C function pointers (created once, never GC'd)
const C_KEY_CALLBACK_PTR = Ref{Ptr{Cvoid}}(C_NULL)
const C_MOUSE_BUTTON_CALLBACK_PTR = Ref{Ptr{Cvoid}}(C_NULL)
const C_CURSOR_POS_CALLBACK_PTR = Ref{Ptr{Cvoid}}(C_NULL)
const C_CHAR_CALLBACK_PTR = Ref{Ptr{Cvoid}}(C_NULL)
const C_SCROLL_CALLBACK_PTR = Ref{Ptr{Cvoid}}(C_NULL)
const C_ERROR_CALLBACK_PTR = Ref{Ptr{Cvoid}}(C_NULL)

# Hard-coded callback implementations - directly modify InputState
# No function storage, no dynamic dispatch

@noinline function _key_callback_wrapper(window::Window, key::Key, scancode::Cint, action::Action, mods_raw::Cint)
    mouse_state = GLOBAL_INPUT_STATE[]
    if mouse_state === nothing
        return nothing
    end

    try
        mods = Int32(mods_raw)
        if action == PRESS || action == REPEAT
            # Create KeyEvent struct - get the type from the array element type
            if !isempty(mouse_state.key_events)
                KeyEventType = typeof(mouse_state.key_events[1])
                key_event = KeyEventType(Int32(key), scancode, Int32(action), mods)
            else
                # If empty, use eltype to get the element type
                KeyEventType = eltype(mouse_state.key_events)
                key_event = KeyEventType(Int32(key), scancode, Int32(action), mods)
            end
            push!(mouse_state.key_events, key_event)

            # Handle special keys that produce characters
            if key == KEY_ENTER
                push!(mouse_state.key_buffer, '\n')
            elseif key == KEY_BACKSPACE
                push!(mouse_state.key_buffer, '\b')
            elseif key == KEY_TAB
                push!(mouse_state.key_buffer, '\t')
            end
        end

        # Update modifier keys - construct using the parent module's ModifierKeys type
        current_mods = mouse_state.modifier_keys
        ModifierKeysType = typeof(current_mods)

        if key == KEY_LEFT_SHIFT || key == KEY_RIGHT_SHIFT
            new_shift = (action == PRESS || action == REPEAT)
            mouse_state.modifier_keys = ModifierKeysType(new_shift, current_mods.control, current_mods.alt,
                current_mods.super, current_mods.caps_lock, current_mods.num_lock)
        elseif key == KEY_LEFT_CONTROL || key == KEY_RIGHT_CONTROL
            new_control = (action == PRESS || action == REPEAT)
            mouse_state.modifier_keys = ModifierKeysType(current_mods.shift, new_control, current_mods.alt,
                current_mods.super, current_mods.caps_lock, current_mods.num_lock)
        elseif key == KEY_LEFT_ALT || key == KEY_RIGHT_ALT
            new_alt = (action == PRESS || action == REPEAT)
            mouse_state.modifier_keys = ModifierKeysType(current_mods.shift, current_mods.control, new_alt,
                current_mods.super, current_mods.caps_lock, current_mods.num_lock)
        elseif key == KEY_LEFT_SUPER || key == KEY_RIGHT_SUPER
            new_super = (action == PRESS || action == REPEAT)
            mouse_state.modifier_keys = ModifierKeysType(current_mods.shift, current_mods.control, current_mods.alt,
                new_super, current_mods.caps_lock, current_mods.num_lock)
        end
    catch e
        # Silently ignore errors for JuliaC compatibility
    end
    return nothing
end

@noinline function _mouse_button_callback_wrapper(window::Window, button::MouseButton, action::Action, mods::Cint)
    mouse_state = GLOBAL_INPUT_STATE[]
    if mouse_state === nothing
        return nothing
    end

    try
        # Map GLFW button to integer (0=left, 1=right, 2=middle)
        button_int = Int(button)

        # Get the MouseButton enum type from the parent module by inspecting the dict keys
        # The dictionaries use the parent module's MouseButton enum as keys
        ButtonEnumType = keytype(mouse_state.button_state)
        ButtonStateType = valtype(mouse_state.button_state)

        # Convert integer to the correct enum type
        # This works because Julia enums can be constructed from integers
        mapped_button = ButtonEnumType(button_int)

        current_time = time()
        current_pos = (mouse_state.x, mouse_state.y)

        if action == PRESS
            mouse_state.button_state[mapped_button] = ButtonStateType(1)  # IsPressed = 1
            mouse_state.mouse_down[mapped_button] = true

            # Start potential drag
            mouse_state.drag_start_position[mapped_button] = current_pos
            mouse_state.is_dragging[mapped_button] = false
            mouse_state.last_drag_position[mapped_button] = nothing

        elseif action == RELEASE
            mouse_state.button_state[mapped_button] = ButtonStateType(0)  # IsReleased = 0
            mouse_state.mouse_up[mapped_button] = true

            # Check for double-click
            time_since_last_click = current_time - mouse_state.last_click_time
            distance_from_last_click = sqrt((current_pos[1] - mouse_state.last_click_position[1])^2 +
                                            (current_pos[2] - mouse_state.last_click_position[2])^2)

            if (time_since_last_click <= mouse_state.double_click_threshold &&
                distance_from_last_click <= 5.0)
                mouse_state.was_double_clicked[mapped_button] = true
            else
                mouse_state.was_clicked[mapped_button] = true
            end

            # Update last click info
            mouse_state.last_click_time = current_time
            mouse_state.last_click_position = current_pos

            # End drag
            mouse_state.drag_start_position[mapped_button] = nothing
            mouse_state.is_dragging[mapped_button] = false
            mouse_state.last_drag_position[mapped_button] = nothing
        end
    catch e
        # Silently ignore errors
    end
    return nothing
end

@noinline function _cursor_pos_callback_wrapper(window::Window, xpos::Cdouble, ypos::Cdouble)
    mouse_state = GLOBAL_INPUT_STATE[]
    if mouse_state === nothing
        return nothing
    end

    try
        x_pos = Float64(xpos)
        y_pos = Float64(ypos)
        current_pos = (x_pos, y_pos)

        # Get the enum types
        ButtonEnumType = keytype(mouse_state.button_state)
        ButtonStateType = valtype(mouse_state.button_state)

        # Iterate over all mouse buttons (LeftButton=0, RightButton=1, MiddleButton=2)
        for button_int in 0:2
            button = ButtonEnumType(button_int)

            if get(mouse_state.is_dragging, button, false)
                mouse_state.last_drag_position[button] = (mouse_state.x, mouse_state.y)
            end
        end

        # Update current position
        mouse_state.x = x_pos
        mouse_state.y = y_pos

        # Check if we should start dragging
        for button_int in 0:2
            button = ButtonEnumType(button_int)
            button_state = get(mouse_state.button_state, button, ButtonStateType(0))

            if (button_state == ButtonStateType(1) &&  # IsPressed
                get(mouse_state.drag_start_position, button, nothing) !== nothing &&
                !get(mouse_state.is_dragging, button, false))

                start_pos = mouse_state.drag_start_position[button]
                distance = sqrt((x_pos - start_pos[1])^2 + (y_pos - start_pos[2])^2)

                if distance > 3.0  # 3 pixel threshold
                    mouse_state.is_dragging[button] = true
                    mouse_state.last_drag_position[button] = start_pos
                end
            end
        end
    catch e
        # Silently ignore errors
    end
    return nothing
end

@noinline function _char_callback_wrapper(window::Window, codepoint::Cuint)
    mouse_state = GLOBAL_INPUT_STATE[]
    if mouse_state === nothing
        return nothing
    end

    try
        # Drop input if buffer is too large
        if length(mouse_state.key_buffer) >= 50
            return nothing
        end
        push!(mouse_state.key_buffer, Char(codepoint))
    catch e
        # Silently ignore errors
    end
    return nothing
end

@noinline function _scroll_callback_wrapper(window::Window, xoffset::Cdouble, yoffset::Cdouble)
    mouse_state = GLOBAL_INPUT_STATE[]
    if mouse_state === nothing
        return nothing
    end

    try
        mouse_state.scroll_x = Float64(xoffset)
        mouse_state.scroll_y = Float64(yoffset)
    catch e
        # Silently ignore errors
    end
    return nothing
end

@noinline function _error_callback_wrapper(code::Cint, description::Cstring)
    @warn GLFWError(code, unsafe_string(description))
    return nothing
end

# Initialize C function pointers at module load
function __init_callbacks__()
    # Create C function pointers - these are kept alive for the lifetime of the module
    C_KEY_CALLBACK_PTR[] = @cfunction(_key_callback_wrapper, Cvoid, (Window, Key, Cint, Action, Cint))
    C_MOUSE_BUTTON_CALLBACK_PTR[] = @cfunction(_mouse_button_callback_wrapper, Cvoid, (Window, MouseButton, Action, Cint))
    C_CURSOR_POS_CALLBACK_PTR[] = @cfunction(_cursor_pos_callback_wrapper, Cvoid, (Window, Cdouble, Cdouble))
    C_CHAR_CALLBACK_PTR[] = @cfunction(_char_callback_wrapper, Cvoid, (Window, Cuint))
    C_SCROLL_CALLBACK_PTR[] = @cfunction(_scroll_callback_wrapper, Cvoid, (Window, Cdouble, Cdouble))
    C_ERROR_CALLBACK_PTR[] = @cfunction(_error_callback_wrapper, Cvoid, (Cint, Cstring))
end

# High-level API for normal Julia use
function SetErrorCallback()
    require_main_thread()
    if C_ERROR_CALLBACK_PTR[] == C_NULL
        __init_callbacks__()
    end
    ccall((:glfwSetErrorCallback, libglfw), Ptr{Cvoid}, (Ptr{Cvoid},), C_ERROR_CALLBACK_PTR[])
    return nothing
end

function SetKeyCallback(window::Window, callback::Union{Nothing,Function}=nothing)
    require_main_thread()
    USER_KEY_CALLBACK[] = callback

    if C_KEY_CALLBACK_PTR[] == C_NULL
        __init_callbacks__()
    end

    if callback === nothing
        # Clear the callback
        ccall((:glfwSetKeyCallback, libglfw), Ptr{Cvoid}, (Window, Ptr{Cvoid}), window, C_NULL)
    else
        # Set our wrapper which will call the stored callback
        ccall((:glfwSetKeyCallback, libglfw), Ptr{Cvoid}, (Window, Ptr{Cvoid}), window, C_KEY_CALLBACK_PTR[])
    end
    return nothing
end

function SetMouseButtonCallback(window::Window, callback::Union{Nothing,Function}=nothing)
    require_main_thread()
    USER_MOUSE_BUTTON_CALLBACK[] = callback

    if C_MOUSE_BUTTON_CALLBACK_PTR[] == C_NULL
        __init_callbacks__()
    end

    if callback === nothing
        ccall((:glfwSetMouseButtonCallback, libglfw), Ptr{Cvoid}, (Window, Ptr{Cvoid}), window, C_NULL)
    else
        ccall((:glfwSetMouseButtonCallback, libglfw), Ptr{Cvoid}, (Window, Ptr{Cvoid}), window, C_MOUSE_BUTTON_CALLBACK_PTR[])
    end
    return nothing
end

function SetCursorPosCallback(window::Window, callback::Union{Nothing,Function}=nothing)
    require_main_thread()
    USER_CURSOR_POS_CALLBACK[] = callback

    if C_CURSOR_POS_CALLBACK_PTR[] == C_NULL
        __init_callbacks__()
    end

    if callback === nothing
        ccall((:glfwSetCursorPosCallback, libglfw), Ptr{Cvoid}, (Window, Ptr{Cvoid}), window, C_NULL)
    else
        ccall((:glfwSetCursorPosCallback, libglfw), Ptr{Cvoid}, (Window, Ptr{Cvoid}), window, C_CURSOR_POS_CALLBACK_PTR[])
    end
    return nothing
end

function SetCharCallback(window::Window, callback::Union{Nothing,Function}=nothing)
    require_main_thread()
    USER_CHAR_CALLBACK[] = callback

    if C_CHAR_CALLBACK_PTR[] == C_NULL
        __init_callbacks__()
    end

    if callback === nothing
        ccall((:glfwSetCharCallback, libglfw), Ptr{Cvoid}, (Window, Ptr{Cvoid}), window, C_NULL)
    else
        ccall((:glfwSetCharCallback, libglfw), Ptr{Cvoid}, (Window, Ptr{Cvoid}), window, C_CHAR_CALLBACK_PTR[])
    end
    return nothing
end

function SetScrollCallback(window::Window, callback::Union{Nothing,Function}=nothing)
    require_main_thread()
    USER_SCROLL_CALLBACK[] = callback

    if C_SCROLL_CALLBACK_PTR[] == C_NULL
        __init_callbacks__()
    end

    if callback === nothing
        ccall((:glfwSetScrollCallback, libglfw), Ptr{Cvoid}, (Window, Ptr{Cvoid}), window, C_NULL)
    else
        ccall((:glfwSetScrollCallback, libglfw), Ptr{Cvoid}, (Window, Ptr{Cvoid}), window, C_SCROLL_CALLBACK_PTR[])
    end
    return nothing
end

# Low-level API for JuliaC and advanced use - accepts raw C function pointers
function SetKeyCallbackPtr(window::Window, callback_ptr::Ptr{Cvoid})
    require_main_thread()
    ccall((:glfwSetKeyCallback, libglfw), Ptr{Cvoid}, (Window, Ptr{Cvoid}), window, callback_ptr)
    return nothing
end

function SetMouseButtonCallbackPtr(window::Window, callback_ptr::Ptr{Cvoid})
    require_main_thread()
    ccall((:glfwSetMouseButtonCallback, libglfw), Ptr{Cvoid}, (Window, Ptr{Cvoid}), window, callback_ptr)
    return nothing
end

function SetCursorPosCallbackPtr(window::Window, callback_ptr::Ptr{Cvoid})
    require_main_thread()
    ccall((:glfwSetCursorPosCallback, libglfw), Ptr{Cvoid}, (Window, Ptr{Cvoid}), window, callback_ptr)
    return nothing
end

function SetCharCallbackPtr(window::Window, callback_ptr::Ptr{Cvoid})
    require_main_thread()
    ccall((:glfwSetCharCallback, libglfw), Ptr{Cvoid}, (Window, Ptr{Cvoid}), window, callback_ptr)
    return nothing
end

function SetScrollCallbackPtr(window::Window, callback_ptr::Ptr{Cvoid})
    require_main_thread()
    ccall((:glfwSetScrollCallback, libglfw), Ptr{Cvoid}, (Window, Ptr{Cvoid}), window, callback_ptr)
    return nothing
end

# Clear functions
function ClearKeyCallback(window::Window)
    require_main_thread()
    USER_KEY_CALLBACK[] = nothing
    ccall((:glfwSetKeyCallback, libglfw), Ptr{Cvoid}, (Window, Ptr{Cvoid}), window, C_NULL)
    return nothing
end

function ClearMouseButtonCallback(window::Window)
    require_main_thread()
    USER_MOUSE_BUTTON_CALLBACK[] = nothing
    ccall((:glfwSetMouseButtonCallback, libglfw), Ptr{Cvoid}, (Window, Ptr{Cvoid}), window, C_NULL)
    return nothing
end

function ClearCursorPosCallback(window::Window)
    require_main_thread()
    USER_CURSOR_POS_CALLBACK[] = nothing
    ccall((:glfwSetCursorPosCallback, libglfw), Ptr{Cvoid}, (Window, Ptr{Cvoid}), window, C_NULL)
    return nothing
end

function ClearCharCallback(window::Window)
    require_main_thread()
    USER_CHAR_CALLBACK[] = nothing
    ccall((:glfwSetCharCallback, libglfw), Ptr{Cvoid}, (Window, Ptr{Cvoid}), window, C_NULL)
    return nothing
end

function ClearScrollCallback(window::Window)
    require_main_thread()
    USER_SCROLL_CALLBACK[] = nothing
    ccall((:glfwSetScrollCallback, libglfw), Ptr{Cvoid}, (Window, Ptr{Cvoid}), window, C_NULL)
    return nothing
end
