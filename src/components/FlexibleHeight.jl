"""
Wraps a child view and forces `preferred_height` to return `false`, making the
component consume all available height from its parent layout regardless of the
child's own intrinsic height preference.
"""
struct FlexibleHeightView <: SizedView
    child::AbstractView
end

function FlexibleHeight(child::AbstractView=EmptyView())
    return FlexibleHeightView(child)
end

function interpret_view(view::FlexibleHeightView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32)
    interpret_view(view.child, x, y, width, height, projection_matrix, mouse_x, mouse_y)
end

function detect_click(view::FlexibleHeightView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32, parent_z::Int32)::Union{ClickResult,Nothing}
    return detect_click(view.child, mouse_state, x, y, width, height, Int32(parent_z + 1))
end

function measure(view::FlexibleHeightView)::Tuple{Float32,Float32}
    return measure(view.child)
end

function measure_width(view::FlexibleHeightView, available_height::Float32)::Float32
    return measure_width(view.child, available_height)
end

function measure_height(view::FlexibleHeightView, available_width::Float32)::Float32
    return measure_height(view.child, available_width)
end

function preferred_width(view::FlexibleHeightView)::Bool
    return preferred_width(view.child)
end

function preferred_height(::FlexibleHeightView)::Bool
    return false
end
