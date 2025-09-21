struct IntrinsicHeightView <: SizedView
    child::AbstractView
end

function IntrinsicHeight(child::AbstractView=EmptyView())
    return IntrinsicHeightView(child)
end

function apply_layout(view::IntrinsicHeightView, x::Float32, y::Float32, width::Float32, height::Float32)
    # Measure the intrinsic size of the child
    intrinsic_width, intrinsic_height = measure(view.child)

    # Use the intrinsic size instead of the parent's size
    final_width = width
    final_height = min(intrinsic_height, height)

    return apply_layout(view.child, x, y, final_width, final_height)
end

function interpret_view(view::IntrinsicHeightView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    # Render the child view using its intrinsic size
    intrinsic_width, intrinsic_height = measure(view.child)
    final_width = width
    final_height = min(intrinsic_height, height)

    interpret_view(view.child, x, y, final_width, final_height, projection_matrix)
end

function detect_click(view::IntrinsicHeightView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32)
    # Forward the click detection to the child
    detect_click(view.child, mouse_state, x, y, width, height)
end

function measure(view::IntrinsicHeightView)::Tuple{Float32,Float32}
    child_width, child_height = measure(view.child)
    return (Inf32, child_height)
end

function measure_height(view::IntrinsicHeightView, available_width::Float32)::Float32
    # Measure the intrinsic height of the child
    return measure_height(view.child, available_width)
end

function preferred_height(view::IntrinsicHeightView)::Bool
    return true
end