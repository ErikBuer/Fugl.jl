# Static Callback System for Static Compilation
# This eliminates all dynamic dispatch by using only hardcoded functions

const Callback = Union{Function,Nothing}

# Storage for user-provided callbacks (Fugl integration)
const USER_MOUSE_BUTTON_CALLBACK = Ref{Any}(nothing)
const USER_CURSOR_POS_CALLBACK = Ref{Any}(nothing)
const USER_KEY_CALLBACK = Ref{Any}(nothing)
const USER_CHAR_CALLBACK = Ref{Any}(nothing)
const USER_SCROLL_CALLBACK = Ref{Any}(nothing)
const USER_CHAR_MODS_CALLBACK = Ref{Any}(nothing)
const USER_CURSOR_ENTER_CALLBACK = Ref{Any}(nothing)
const USER_DROP_CALLBACK = Ref{Any}(nothing)

# Static callback functions - no storage, no dynamic dispatch
@noinline function _error_callback(error::GLFWError)
    # User callback is hardcoded - change this line to modify behavior
    @warn error
    return nothing
end

@noinline function _key_callback(window::Window, key::Key, scancode::Cint, action::Action, mods::Cint)
    # Call user-provided callback if set
    cb = USER_KEY_CALLBACK[]
    if cb !== nothing
        cb(window, key, scancode, action, mods)
    elseif key == KEY_ESCAPE && action == PRESS
        # Default: close on escape
        SetWindowShouldClose(window, true)
    end
    return nothing
end

@noinline function _mouse_button_callback(window::Window, button::MouseButton, action::Action, mods::Cint)
    # Call user-provided callback if set
    cb = USER_MOUSE_BUTTON_CALLBACK[]
    if cb !== nothing
        cb(window, button, action, mods)
    end
    return nothing
end

@noinline function _cursor_pos_callback(window::Window, xpos::Cdouble, ypos::Cdouble)
    # Call user-provided callback if set
    cb = USER_CURSOR_POS_CALLBACK[]
    if cb !== nothing
        cb(window, xpos, ypos)
    end
    return nothing
end

@noinline function _char_callback(window::Window, codepoint::Cuint)
    # Call user-provided callback if set
    cb = USER_CHAR_CALLBACK[]
    if cb !== nothing
        cb(window, codepoint)
    end
    return nothing
end

@noinline function _scroll_callback(window::Window, xoffset::Cdouble, yoffset::Cdouble)
    # Call user-provided callback if set
    cb = USER_SCROLL_CALLBACK[]
    if cb !== nothing
        cb(window, xoffset, yoffset)
    end
    return nothing
end

@noinline function _char_mods_callback(window::Window, codepoint::Cuint, mods::Cint)
    # Call user-provided callback if set
    cb = USER_CHAR_MODS_CALLBACK[]
    if cb !== nothing
        cb(window, codepoint, mods)
    end
    return nothing
end

@noinline function _cursor_enter_callback(window::Window, entered::Cint)
    # Call user-provided callback if set
    cb = USER_CURSOR_ENTER_CALLBACK[]
    if cb !== nothing
        cb(window, Bool(entered))
    end
    return nothing
end

@noinline function _drop_callback(window::Window, count::Cint, paths::Ptr{Cstring})
    # Call user-provided callback if set
    cb = USER_DROP_CALLBACK[]
    if cb !== nothing
        # Convert C string array to Julia array
        path_array = unsafe_wrap(Array, paths, count)
        julia_paths = [unsafe_string(path_array[i]) for i in 1:count]
        cb(window, julia_paths)
    end
    return nothing
end

# Completely static callback wrappers - no storage access
@noinline function _ErrorCallbackWrapper(code::Cint, description::Cstring)
    # Direct hardcoded call - completely static, no storage
    _error_callback(GLFWError(code, unsafe_string(description)))
    return nothing
end

@noinline function _KeyCallbackWrapper(window::Window, key::Key, scancode::Cint, action::Action, mods::Cint)
    # Direct hardcoded call - completely static, no storage
    _key_callback(window, key, scancode, action, mods)
    return nothing
end

@noinline function _MouseButtonCallbackWrapper(window::Window, button::MouseButton, action::Action, mods::Cint)
    _mouse_button_callback(window, button, action, mods)
    return nothing
end

@noinline function _CursorPosCallbackWrapper(window::Window, xpos::Cdouble, ypos::Cdouble)
    _cursor_pos_callback(window, xpos, ypos)
    return nothing
end

@noinline function _CharCallbackWrapper(window::Window, codepoint::Cuint)
    _char_callback(window, codepoint)
    return nothing
end

@noinline function _ScrollCallbackWrapper(window::Window, xoffset::Cdouble, yoffset::Cdouble)
    _scroll_callback(window, xoffset, yoffset)
    return nothing
end

@noinline function _CharModsCallbackWrapper(window::Window, codepoint::Cuint, mods::Cint)
    _char_mods_callback(window, codepoint, mods)
    return nothing
end

@noinline function _CursorEnterCallbackWrapper(window::Window, entered::Cint)
    _cursor_enter_callback(window, entered)
    return nothing
end

@noinline function _DropCallbackWrapper(window::Window, count::Cint, paths::Ptr{Cstring})
    _drop_callback(window, count, paths)
    return nothing
end

# Compile-time constant C function pointers
const ERROR_PTR = @cfunction(_ErrorCallbackWrapper, Cvoid, (Cint, Cstring))
const KEY_PTR = @cfunction(_KeyCallbackWrapper, Cvoid, (Window, Key, Cint, Action, Cint))
const MOUSE_BUTTON_PTR = @cfunction(_MouseButtonCallbackWrapper, Cvoid, (Window, MouseButton, Action, Cint))
const CURSOR_POS_PTR = @cfunction(_CursorPosCallbackWrapper, Cvoid, (Window, Cdouble, Cdouble))
const CHAR_PTR = @cfunction(_CharCallbackWrapper, Cvoid, (Window, Cuint))
const SCROLL_PTR = @cfunction(_ScrollCallbackWrapper, Cvoid, (Window, Cdouble, Cdouble))
const CHAR_MODS_PTR = @cfunction(_CharModsCallbackWrapper, Cvoid, (Window, Cuint, Cint))
const CURSOR_ENTER_PTR = @cfunction(_CursorEnterCallbackWrapper, Cvoid, (Window, Cint))
const DROP_PTR = @cfunction(_DropCallbackWrapper, Cvoid, (Window, Cint, Ptr{Cstring}))

# Static setters - no customization, but guaranteed to work with static compilation
function SetErrorCallback()
    require_main_thread()
    ccall((:glfwSetErrorCallback, libglfw), Ptr{Cvoid}, (Ptr{Cvoid},), ERROR_PTR)
    return nothing
end

function SetKeyCallback(window::Window, callback=nothing)
    require_main_thread()
    USER_KEY_CALLBACK[] = callback
    ccall((:glfwSetKeyCallback, libglfw), Ptr{Cvoid}, (Window, Ptr{Cvoid}), window, KEY_PTR)
    return nothing
end

function SetMouseButtonCallback(window::Window, callback=nothing)
    require_main_thread()
    USER_MOUSE_BUTTON_CALLBACK[] = callback
    ccall((:glfwSetMouseButtonCallback, libglfw), Ptr{Cvoid}, (Window, Ptr{Cvoid}), window, MOUSE_BUTTON_PTR)
    return nothing
end

function SetCursorPosCallback(window::Window, callback=nothing)
    require_main_thread()
    USER_CURSOR_POS_CALLBACK[] = callback
    ccall((:glfwSetCursorPosCallback, libglfw), Ptr{Cvoid}, (Window, Ptr{Cvoid}), window, CURSOR_POS_PTR)
    return nothing
end

function SetCharCallback(window::Window, callback=nothing)
    require_main_thread()
    USER_CHAR_CALLBACK[] = callback
    ccall((:glfwSetCharCallback, libglfw), Ptr{Cvoid}, (Window, Ptr{Cvoid}), window, CHAR_PTR)
    return nothing
end

function SetScrollCallback(window::Window, callback=nothing)
    require_main_thread()
    USER_SCROLL_CALLBACK[] = callback
    ccall((:glfwSetScrollCallback, libglfw), Ptr{Cvoid}, (Window, Ptr{Cvoid}), window, SCROLL_PTR)
    return nothing
end

function SetCharModsCallback(window::Window, callback=nothing)
    require_main_thread()
    USER_CHAR_MODS_CALLBACK[] = callback
    ccall((:glfwSetCharModsCallback, libglfw), Ptr{Cvoid}, (Window, Ptr{Cvoid}), window, CHAR_MODS_PTR)
    return nothing
end

function SetCursorEnterCallback(window::Window, callback=nothing)
    require_main_thread()
    USER_CURSOR_ENTER_CALLBACK[] = callback
    ccall((:glfwSetCursorEnterCallback, libglfw), Ptr{Cvoid}, (Window, Ptr{Cvoid}), window, CURSOR_ENTER_PTR)
    return nothing
end

function SetDropCallback(window::Window, callback=nothing)
    require_main_thread()
    USER_DROP_CALLBACK[] = callback
    ccall((:glfwSetDropCallback, libglfw), Ptr{Cvoid}, (Window, Ptr{Cvoid}), window, DROP_PTR)
    return nothing
end

# Clear functions
function ClearErrorCallback()
    require_main_thread()
    ccall((:glfwSetErrorCallback, libglfw), Ptr{Cvoid}, (Ptr{Cvoid},), C_NULL)
    return nothing
end

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

function ClearCharModsCallback(window::Window)
    require_main_thread()
    USER_CHAR_MODS_CALLBACK[] = nothing
    ccall((:glfwSetCharModsCallback, libglfw), Ptr{Cvoid}, (Window, Ptr{Cvoid}), window, C_NULL)
    return nothing
end

function ClearCursorEnterCallback(window::Window)
    require_main_thread()
    USER_CURSOR_ENTER_CALLBACK[] = nothing
    ccall((:glfwSetCursorEnterCallback, libglfw), Ptr{Cvoid}, (Window, Ptr{Cvoid}), window, C_NULL)
    return nothing
end

function ClearDropCallback(window::Window)
    require_main_thread()
    USER_DROP_CALLBACK[] = nothing
    ccall((:glfwSetDropCallback, libglfw), Ptr{Cvoid}, (Window, Ptr{Cvoid}), window, C_NULL)
    return nothing
end
