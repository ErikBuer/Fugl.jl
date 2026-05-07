"""
Wraps a child view and forces `preferred_width` to return `false`, making the
component consume all available width from its parent layout (e.g. a Row or
Column) regardless of the child's own intrinsic width preference.
"""
struct FlexibleWidthView <: SizedView
    child::AbstractView
end

function FlexibleWidth(child::AbstractView=EmptyView())
    return FlexibleWidthView(child)
end

function interpret_view(view::FlexibleWidthView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, cursor_position::Point2f)
    interpret_view(view.child, x, y, width, height, projection_matrix, cursor_position)
end

function detect_click(view::FlexibleWidthView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32, parent_z::Int32)::Union{ClickResult,Nothing}
    return detect_click(view.child, mouse_state, x, y, width, height, Int32(parent_z + 1))
end

function measure(view::FlexibleWidthView)::Tuple{Float32,Float32}
    return measure(view.child)
end

function measure_width(view::FlexibleWidthView, available_height::Float32)::Float32
    return measure_width(view.child, available_height)
end

function measure_height(view::FlexibleWidthView, available_width::Float32)::Float32
    return measure_height(view.child, available_width)
end

function preferred_width(::FlexibleWidthView)::Bool
    return false
end

function preferred_height(view::FlexibleWidthView)::Bool
    return preferred_height(view.child)
end
