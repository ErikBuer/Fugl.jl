abstract type AbstractView end

"""
Abstract type for views that have constrained/intrinsic sizing behavior.
These views know their preferred dimensions and can be used with alignment components.
Examples: IntrinsicSize, FixedSize, IntrinsicWidth, IntrinsicHeight, etc.
"""
abstract type SizedView <: AbstractView end

"""
    interpret_view(component::AbstractView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})

Interpret the view of a GUI component.
This function is responsible for interpreting the view of a GUI component based on its layout and properties.
"""
function interpret_view(component::AbstractView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    error("interpret_view not implemented for component of type $(typeof(component))")
end

"""
    apply_layout(component::AbstractView)

Apply layout to a GUI component and its children.
This function calculates and applies the layout to components.
The `interpret_view` function then uses the positions and sizes calculated by this function.
"""
function apply_layout(component::AbstractView)
    error("apply_layout is not implemented for $(typeof(component))")
end

function handle_key_input(component::AbstractView, mouse_state::InputState)
    error("handle_key_input is not implemented for $(typeof(component))")
end

function detect_click(view::AbstractView, mouse_state::InputState, x::AbstractFloat, y::AbstractFloat, width::AbstractFloat, height::AbstractFloat)
    nothing
end

function measure(view::AbstractView)::Tuple{Float32,Float32}
    # Default implementation: components occupy the parent's size
    return (Inf32, Inf32)  # Width and height
end

function preferred_width(view::AbstractView)::Bool
    return false
end

function preferred_height(view::AbstractView)::Bool
    return false
end

@inline function preferred_size(view::AbstractView)::Bool
    return preferred_width(view) || preferred_height(view)
end