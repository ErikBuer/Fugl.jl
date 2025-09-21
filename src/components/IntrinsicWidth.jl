struct IntrinsicWidthView <: SizedView
    child::AbstractView
end

function IntrinsicWidth(child::AbstractView=EmptyView())
    return IntrinsicWidthView(child)
end

function apply_layout(view::IntrinsicWidthView, x::Float32, y::Float32, width::Float32, height::Float32)
    # Measure the intrinsic size of the child
    intrinsic_width, intrinsic_height = measure(view.child)

    # Use the intrinsic size instead of the parent's size
    final_width = min(intrinsic_width, width)
    final_height = height

    return apply_layout(view.child, x, y, final_width, final_height)
end

function interpret_view(view::IntrinsicWidthView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    # Render the child view using its intrinsic size
    intrinsic_width, intrinsic_height = measure(view.child)
    final_width = min(intrinsic_width, width)
    final_height = height

    interpret_view(view.child, x, y, final_width, final_height, projection_matrix)
end

function detect_click(view::IntrinsicWidthView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32)
    # Forward the click detection to the child
    detect_click(view.child, mouse_state, x, y, width, height)
end

function measure(view::IntrinsicWidthView)::Tuple{Float32,Float32}
    child_width, child_height = measure(view.child)
    return (child_width, Inf32)
end

function measure_width(view::IntrinsicWidthView, available_height::Float32)::Float32
    # Measure the intrinsic width of the child
    return measure_width(view.child, available_height)
end

function preferred_width(view::IntrinsicWidthView)::Bool
    return true
end