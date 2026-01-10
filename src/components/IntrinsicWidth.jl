struct IntrinsicWidthView <: SizedView
    child::AbstractView
end

function IntrinsicWidth(child::AbstractView=EmptyView())
    return IntrinsicWidthView(child)
end

function interpret_view(view::IntrinsicWidthView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32)
    # Render the child view using its intrinsic size
    intrinsic_width = measure_width(view.child, height)
    final_width = min(intrinsic_width, width)

    interpret_view(view.child, x, y, final_width, height, projection_matrix, mouse_x, mouse_y)
end

function detect_click(view::IntrinsicWidthView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32, parent_z::Int32)::Union{ClickResult,Nothing}
    # Use the same width calculation as interpret_view
    intrinsic_width = measure_width(view.child, height)
    final_width = min(intrinsic_width, width)

    # Forward the click detection to the child with correct dimensions
    return detect_click(view.child, mouse_state, x, y, final_width, height, Int32(parent_z + 1))
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