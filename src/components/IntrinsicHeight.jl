struct IntrinsicHeightView <: SizedView
    child::AbstractView
end

function IntrinsicHeight(child::AbstractView=EmptyView())
    return IntrinsicHeightView(child)
end

function interpret_view(view::IntrinsicHeightView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32)
    # Render the child view using its intrinsic size
    intrinsic_height = measure_height(view.child, width)
    final_height = min(intrinsic_height, height)

    interpret_view(view.child, x, y, width, final_height, projection_matrix, mouse_x, mouse_y)
end

function detect_click(view::IntrinsicHeightView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32, z_order::Int32=Int32(0))::Union{ClickResult,Nothing}
    # Use the same height calculation as interpret_view
    intrinsic_height = measure_height(view.child, width)
    final_height = min(intrinsic_height, height)

    # Forward the click detection to the child with correct dimensions
    return detect_click(view.child, mouse_state, x, y, width, final_height, z_order)
end

function measure(view::IntrinsicHeightView)::Tuple{Float32,Float32}
    child_width, child_height = measure(view.child)
    return (Inf32, child_height)
end

function measure_width(view::IntrinsicHeightView, available_height::Float32)::Float32
    # Measure the width of the child when constrained by available height
    return measure_width(view.child, available_height)
end

function measure_height(view::IntrinsicHeightView, available_width::Float32)::Float32
    # Measure the intrinsic height of the child
    return measure_height(view.child, available_width)
end

function preferred_height(view::IntrinsicHeightView)::Bool
    return true
end