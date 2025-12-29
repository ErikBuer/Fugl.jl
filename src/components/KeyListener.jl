struct KeyListenerView <: AbstractView
    child::AbstractView  # Wrapped component
    target_key::Int32  # GLFW key to listen for (e.g., Int32(GLFW.KEY_A), Int32(GLFW.KEY_ENTER))
    modifiers::Union{Nothing,Int32}  # Optional modifier flags (GLFW.MOD_CONTROL, etc.)
    on_key_press::Function  # Callback when target key is pressed
end

"""
KeyListener wraps another component and triggers a callback when a specific key is pressed.
This allows adding keyboard shortcuts to any component.

Usage:
- `KeyListener(my_component, GLFW.KEY_A, () -> println("A pressed"))`
- `KeyListener(my_component, GLFW.KEY_ENTER, () -> save_file())`
- `KeyListener(my_component, GLFW.KEY_S, GLFW.MOD_CONTROL, () -> save_file())` Ctrl+S
"""
function KeyListener(child::AbstractView, target_key::GLFW.Key, on_key_press::Function)
    return KeyListenerView(child, Int32(target_key), nothing, on_key_press)
end

function KeyListener(child::AbstractView, target_key::GLFW.Key, modifiers::Union{Int32,UInt16}, on_key_press::Function)
    return KeyListenerView(child, Int32(target_key), Int32(modifiers), on_key_press)
end

# Measurement functions - just pass through to child
function measure(view::KeyListenerView)::Tuple{Float32,Float32}
    return measure(view.child)
end

function measure_width(view::KeyListenerView, available_height::Float32)::Float32
    return measure_width(view.child, available_height)
end

function measure_height(view::KeyListenerView, available_width::Float32)::Float32
    return measure_height(view.child, available_width)
end

# Rendering - just pass through to child
function interpret_view(view::KeyListenerView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32)
    # Just render the child - KeyListener is invisible
    interpret_view(view.child, x, y, width, height, projection_matrix, mouse_x, mouse_y)
end

# Key detection
function detect_click(view::KeyListenerView, input_state::InputState, x::AbstractFloat, y::AbstractFloat, width::AbstractFloat, height::AbstractFloat)
    # Check for keyboard events in the input_state
    for key_event in input_state.key_events
        # Check if this is a key press (GLFW.PRESS = 1) for our target key
        if key_event.key == view.target_key && key_event.action == 1  # GLFW.PRESS
            # Check modifiers if specified
            if view.modifiers !== nothing
                if key_event.mods == view.modifiers
                    view.on_key_press()
                    break
                end
            else
                # No modifier requirements, just trigger on key press
                view.on_key_press()
                break
            end
        end
    end

    # Forward to child for normal interaction handling
    detect_click(view.child, input_state, x, y, width, height)
end