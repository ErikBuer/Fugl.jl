"""
Wraps a child view and forces both `preferred_width` and `preferred_height` to
return `false`, making the component consume all available space from its parent
layout regardless of the child's own intrinsic size preferences.
"""
struct FlexibleSizeView <: SizedView
    child::AbstractView
end

function FlexibleSize(child::AbstractView=EmptyView())
    return FlexibleSizeView(child)
end

function interpret_view(view::FlexibleSizeView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, cursor_position::Point2f, window_size::Size)
    interpret_view(view.child, x, y, width, height, projection_matrix, cursor_position, window_size)
end

function detect_click(view::FlexibleSizeView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32, parent_z::Int32)::Union{ClickResult,Nothing}
    return detect_click(view.child, mouse_state, x, y, width, height, Int32(parent_z + 1))
end

function measure(view::FlexibleSizeView)::Tuple{Float32,Float32}
    return measure(view.child)
end

function measure_width(view::FlexibleSizeView, available_height::Float32)::Float32
    return measure_width(view.child, available_height)
end

function measure_height(view::FlexibleSizeView, available_width::Float32)::Float32
    return measure_height(view.child, available_width)
end

function preferred_width(::FlexibleSizeView)::Bool
    return false
end

function preferred_height(::FlexibleSizeView)::Bool
    return false
end
