struct PaddingView <: AbstractView
    child::AbstractView
    padding::Float32
end

"""
Padding component: adds padding around its child, but does not render any graphics.
"""
function Padding(child::AbstractView=EmptyView(), padding::Float32=8.0f0)
    return PaddingView(child, padding)
end

function measure(view::PaddingView)::Tuple{Float32,Float32}
    child_width, child_height = measure(view.child)
    return (child_width + 2 * view.padding, child_height + 2 * view.padding)
end

function measure_width(view::PaddingView, available_height::Float32)::Float32
    child_width = measure_width(view.child, available_height)
    return child_width + 2 * view.padding
end

function measure_height(view::PaddingView, available_width::Float32)::Float32
    child_height = measure_height(view.child, available_width)
    return child_height + 2 * view.padding
end

function apply_layout(view::PaddingView, x::Float32, y::Float32, width::Float32, height::Float32)
    padded_x = x + view.padding
    padded_y = y + view.padding
    padded_width = width - 2 * view.padding
    padded_height = height - 2 * view.padding
    return (padded_x, padded_y, padded_width, padded_height)
end

function interpret_view(view::PaddingView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32)
    child_x, child_y, child_width, child_height = apply_layout(view, x, y, width, height)
    interpret_view(view.child, child_x, child_y, child_width, child_height, projection_matrix, mouse_x, mouse_y)
end

function detect_click(view::PaddingView, mouse_state::InputState, x::AbstractFloat, y::AbstractFloat, width::AbstractFloat, height::AbstractFloat)
    child_x, child_y, child_width, child_height = apply_layout(view, x, y, width, height)
    detect_click(view.child, mouse_state, child_x, child_y, child_width, child_height)
end
