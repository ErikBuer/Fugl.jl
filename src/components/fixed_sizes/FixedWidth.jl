struct FixedWidthView <: SizedView
    child::AbstractView
    width::Float32
end

"""
    FixedWidth(child::AbstractView, width::Real)

Creates a view that has a fixed width but uses the child's intrinsic height.
"""
function FixedWidth(child::AbstractView, width::Real)::FixedWidthView
    FixedWidthView(child, Float32(width))
end

function interpret_view(view::FixedWidthView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32)
    final_width = min(view.width, width)
    interpret_view(view.child, x, y, final_width, height, projection_matrix, mouse_x, mouse_y)
end

function detect_click(view::FixedWidthView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32)
    final_width = min(view.width, width)
    detect_click(view.child, mouse_state, x, y, final_width, height)
end

function measure(view::FixedWidthView)::Tuple{Float32,Float32}
    child_width, child_height = measure(view.child)
    return (view.width, child_height)
end

function measure_width(view::FixedWidthView, available_height::Float32)::Float32
    return view.width
end

function measure_height(view::FixedWidthView, available_width::Float32)::Float32
    return measure_height(view.child, view.width)
end

function preferred_width(view::FixedWidthView)::Bool
    return true
end

function preferred_height(view::FixedWidthView)::Bool
    return preferred_height(view.child)
end