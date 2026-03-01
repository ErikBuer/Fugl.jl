# Callback System for GLFW
# Designed to work with both normal Julia and JuliaC static compilation

# Storage for callbacks - using better typing for type stability
const USER_KEY_CALLBACK = Ref{Union{Nothing, Function}}(nothing)
const USER_MOUSE_BUTTON_CALLBACK = Ref{Union{Nothing, Function}}(nothing)
const USER_CURSOR_POS_CALLBACK = Ref{Union{Nothing, Function}}(nothing)
const USER_CHAR_CALLBACK = Ref{Union{Nothing, Function}}(nothing)
const USER_SCROLL_CALLBACK = Ref{Union{Nothing, Function}}(nothing)

# Module-level C function pointers (created once, never GC'd)
const C_KEY_CALLBACK_PTR = Ref{Ptr{Cvoid}}(C_NULL)
const C_MOUSE_BUTTON_CALLBACK_PTR = Ref{Ptr{Cvoid}}(C_NULL)
const C_CURSOR_POS_CALLBACK_PTR = Ref{Ptr{Cvoid}}(C_NULL)
const C_CHAR_CALLBACK_PTR = Ref{Ptr{Cvoid}}(C_NULL)
const C_SCROLL_CALLBACK_PTR = Ref{Ptr{Cvoid}}(C_NULL)
const C_ERROR_CALLBACK_PTR = Ref{Ptr{Cvoid}}(C_NULL)

# Wrapper functions that call stored Julia callbacks
@noinline function _key_callback_wrapper(window::Window, key::Key, scancode::Cint, action::Action, mods::Cint)
    try
        cb = USER_KEY_CALLBACK[]
        if cb !== nothing
            cb(window, key, scancode, action, mods)
        end
    catch e
        @error "Error in key callback" exception=(e, catch_backtrace())
    end
    return nothing
end

@noinline function _mouse_button_callback_wrapper(window::Window, button::MouseButton, action::Action, mods::Cint)
    try
        cb = USER_MOUSE_BUTTON_CALLBACK[]
        if cb !== nothing
            cb(window, button, action, mods)
        end
    catch e
        @error "Error in mouse button callback" exception=(e, catch_backtrace())
    end
    return nothing
end

@noinline function _cursor_pos_callback_wrapper(window::Window, xpos::Cdouble, ypos::Cdouble)
    try
        cb = USER_CURSOR_POS_CALLBACK[]
        if cb !== nothing
            cb(window, xpos, ypos)
        end
    catch e
        @error "Error in cursor position callback" exception=(e, catch_backtrace())
    end
    return nothing
end

@noinline function _char_callback_wrapper(window::Window, codepoint::Cuint)
    try
        cb = USER_CHAR_CALLBACK[]
        if cb !== nothing
            cb(window, codepoint)
        end
    catch e
        @error "Error in char callback" exception=(e, catch_backtrace())
    end
    return nothing
end

@noinline function _scroll_callback_wrapper(window::Window, xoffset::Cdouble, yoffset::Cdouble)
    try
        cb = USER_SCROLL_CALLBACK[]
        if cb !== nothing
            cb(window, xoffset, yoffset)
        end
    catch e
        @error "Error in scroll callback" exception=(e, catch_backtrace())
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

function SetKeyCallback(window::Window, callback::Union{Nothing, Function}=nothing)
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

function SetMouseButtonCallback(window::Window, callback::Union{Nothing, Function}=nothing)
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

function SetCursorPosCallback(window::Window, callback::Union{Nothing, Function}=nothing)
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

function SetCharCallback(window::Window, callback::Union{Nothing, Function}=nothing)
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

function SetScrollCallback(window::Window, callback::Union{Nothing, Function}=nothing)
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
