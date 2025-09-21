struct FixedSizeView <: SizedView
    child::AbstractView
    width::Float32
    height::Float32
end

"""
    FixedSize(child::AbstractView, width::Real, height::Real)

Creates a view that has a fixed size, regardless of the child's intrinsic size.
The child will be rendered at the specified width and height.
"""
function FixedSize(child::AbstractView, width::Real, height::Real)::FixedSizeView
    FixedSizeView(child, Float32(width), Float32(height))
end

# FixedSize implementation (existing)
function apply_layout(view::FixedSizeView, x::Float32, y::Float32, width::Float32, height::Float32)
    final_width = min(view.width, width)
    final_height = min(view.height, height)
    return (x, y, final_width, final_height)
end

function interpret_view(view::FixedSizeView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    final_width = min(view.width, width)
    final_height = min(view.height, height)
    interpret_view(view.child, x, y, final_width, final_height, projection_matrix)
end

function detect_click(view::FixedSizeView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32)
    final_width = min(view.width, width)
    final_height = min(view.height, height)
    detect_click(view.child, mouse_state, x, y, final_width, final_height)
end

function measure(view::FixedSizeView)::Tuple{Float32,Float32}
    return (view.width, view.height)
end

function preferred_width(view::FixedSizeView)::Bool
    return true
end

function preferred_height(view::FixedSizeView)::Bool
    return true
end