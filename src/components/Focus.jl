struct FocusView <: AbstractView
    child::AbstractView
    is_focused::Bool
    on_focus_change::Function  # Callback when focus changes: (is_focused::Bool) -> nothing
    on_focus::Function         # Callback when focus is gained: () -> nothing
    on_blur::Function          # Callback when focus is lost: () -> nothing
end

"""
Focus wraps a component to provide focus management.
Focus is gained on left mouse button down inside the component.
Focus is lost on left mouse button down outside the component.

Usage:
```julia
focus_state = Ref(false)

Focus(
    my_component;
    is_focused=focus_state[],
    on_focus_change=(focused) -> focus_state[] = focused
)
```
"""
function Focus(child::AbstractView;
    is_focused::Bool=false,
    on_focus_change::Function=(focused::Bool) -> nothing,
    on_focus::Function=() -> nothing,
    on_blur::Function=() -> nothing)
    return FocusView(child, is_focused, on_focus_change, on_focus, on_blur)
end

# Measurement functions - just pass through to child
function measure(view::FocusView)::Tuple{Float32,Float32}
    return measure(view.child)
end

function measure_width(view::FocusView, available_height::Float32)::Float32
    return measure_width(view.child, available_height)
end

function measure_height(view::FocusView, available_width::Float32)::Float32
    return measure_height(view.child, available_width)
end

function apply_layout(view::FocusView, x::Float32, y::Float32, width::Float32, height::Float32)
    return apply_layout(view.child, x, y, width, height)
end

# Rendering - just pass through to child
function interpret_view(view::FocusView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32)
    # Just render the child - Focus is invisible
    interpret_view(view.child, x, y, width, height, projection_matrix, mouse_x, mouse_y)
end

# Focus detection and management
function detect_click(view::FocusView, input_state::InputState, x::AbstractFloat, y::AbstractFloat, width::AbstractFloat, height::AbstractFloat, parent_z::Int32)::Union{ClickResult,Nothing}
    is_mouse_inside = inside_component(view, x, y, width, height, input_state.x, input_state.y)

    # Handle focus changes on left mouse button down
    if get(input_state.mouse_down, LeftButton, false)
        if is_mouse_inside && !view.is_focused
            # Gain focus - mouse down inside and not currently focused
            view.on_focus_change(true)
            view.on_focus()
        elseif !is_mouse_inside && view.is_focused
            # Lose focus - mouse down outside and currently focused
            view.on_focus_change(false)
            view.on_blur()
        end
    end

    # Forward to child with is_focused kwarg
    return detect_click(view.child, input_state, x, y, width, height, Int32(parent_z + 1); is_focused=view.is_focused)
end