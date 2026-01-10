struct FixedHeightView <: SizedView
    child::AbstractView
    height::Float32
end

"""
    FixedHeight(child::AbstractView, height::Real)

Creates a view that has a fixed height but uses the child's intrinsic width.
"""
function FixedHeight(child::AbstractView, height::Real)::FixedHeightView
    FixedHeightView(child, Float32(height))
end

function interpret_view(view::FixedHeightView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32)
    final_height = min(view.height, height)
    interpret_view(view.child, x, y, width, final_height, projection_matrix, mouse_x, mouse_y)
end

function detect_click(view::FixedHeightView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32, parent_z::Int32)::Union{ClickResult,Nothing}
    final_height = min(view.height, height)
    return detect_click(view.child, mouse_state, x, y, width, final_height, Int32(parent_z + 1))
end

function measure(view::FixedHeightView)::Tuple{Float32,Float32}
    child_width, child_height = measure(view.child)
    return (child_width, view.height)
end

function measure_width(view::FixedHeightView, available_height::Float32)::Float32
    return measure_width(view.child, view.height)
end

function measure_height(view::FixedHeightView, available_width::Float32)::Float32
    return view.height
end

function preferred_width(view::FixedHeightView)::Bool
    return preferred_width(view.child)
end

function preferred_height(view::FixedHeightView)::Bool
    return true
end