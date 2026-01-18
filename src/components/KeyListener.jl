struct KeyListenerView <: AbstractView
    child::AbstractView  # Wrapped component
    key_map::Dict{Tuple{Int32,Union{Nothing,Int32}},Function}  # Fast lookup: (key, modifiers) => callback
end

"""
KeyListener wraps another component and triggers callbacks when specific keys are pressed.
This allows adding keyboard shortcuts to any component.

Usage:
- `KeyListener(my_component, GLFW.KEY_A, () -> println("A pressed"))` Single key
- `KeyListener(my_component, GLFW.KEY_S, GLFW.MOD_CONTROL, () -> save_file())` Single key with modifier
- `KeyListener(my_component, [(GLFW.KEY_A, nothing, callback1), (GLFW.KEY_S, GLFW.MOD_CONTROL, callback2)])` Multiple keys
- `KeyListener(my_component, [(GLFW.KEY_A, callback1), (GLFW.KEY_B, callback2)])` Multiple simple keys
"""
function KeyListener(child::AbstractView, target_key::GLFW.Key, on_key_press::Function)
    key_map = Dict{Tuple{Int32,Union{Nothing,Int32}},Function}()
    key_map[(Int32(target_key), nothing)] = on_key_press
    return KeyListenerView(child, key_map)
end

# Single key with modifiers  
function KeyListener(child::AbstractView, target_key::GLFW.Key, modifiers::Union{Int32,UInt16}, on_key_press::Function)
    key_map = Dict{Tuple{Int32,Union{Nothing,Int32}},Function}()
    key_map[(Int32(target_key), Int32(modifiers))] = on_key_press
    return KeyListenerView(child, key_map)
end

# Multiple keys with optional modifiers
function KeyListener(child::AbstractView, key_bindings::Vector{Tuple{GLFW.Key,Union{Nothing,Int32},Function}})
    key_map = Dict{Tuple{Int32,Union{Nothing,Int32}},Function}()
    for (key, mods, callback) in key_bindings
        key_map[(Int32(key), mods)] = callback
    end
    return KeyListenerView(child, key_map)
end

# Multiple keys without modifiers (simple format)
function KeyListener(child::AbstractView, key_bindings::Vector{Tuple{GLFW.Key,Function}})
    key_map = Dict{Tuple{Int32,Union{Nothing,Int32}},Function}()
    for (key, callback) in key_bindings
        key_map[(Int32(key), nothing)] = callback
    end
    return KeyListenerView(child, key_map)
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
# TODO consider passing focus state for visual indication. This would require changes to interpret_view signatures.
function interpret_view(view::KeyListenerView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32)
    # Just render the child - KeyListener is invisible
    interpret_view(view.child, x, y, width, height, projection_matrix, mouse_x, mouse_y)
end

# Key detection - processes keys only when focused
function detect_click(view::KeyListenerView, input_state::InputState, x::AbstractFloat, y::AbstractFloat, width::AbstractFloat, height::AbstractFloat, parent_z::Int32; is_focused::Bool=true)::Union{ClickResult,Nothing}
    # Process keyboard events only when focused
    if !is_focused
        return detect_click(view.child, input_state, x, y, width, height, Int32(parent_z + 1))
    end

    # Check for keyboard events in the input_state
    for key_event in input_state.key_events
        # Check if this is a key press (GLFW.PRESS = 1) 
        if key_event.action == 1  # GLFW.PRESS
            # O(1) hash lookup instead of O(n) linear search
            key_signature = (key_event.key, key_event.mods == 0 ? nothing : key_event.mods)
            callback = get(view.key_map, key_signature, nothing)
            if callback !== nothing
                callback()
                break  # Found and executed callback, stop processing this key event
            end
        end
    end

    # Forward to child for normal interaction handling
    return detect_click(view.child, input_state, x, y, width, height, Int32(parent_z + 1))
end