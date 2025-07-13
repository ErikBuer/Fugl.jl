struct IntrinsicSizeView <: SizedView
    child::AbstractView
end

"""
    IntrinsicSize(child::AbstractView=EmptyView())

The `IntrinsicSize` component is used to wrap a child view and ensure that it uses its intrinsic size for layout.
This is useful for components that should not stretch to fill their parent container, but rather use their natural size.
"""
function IntrinsicSize(child::AbstractView=EmptyView())
    return IntrinsicSizeView(child)
end

function apply_layout(view::IntrinsicSizeView, x::Float32, y::Float32, width::Float32, height::Float32)
    # Measure the intrinsic size of the child
    intrinsic_width, intrinsic_height = measure(view.child)

    # Use the intrinsic size instead of the parent's size
    final_width = min(intrinsic_width, width)
    final_height = min(intrinsic_height, height)

    return apply_layout(view.child, x, y, final_width, final_height)
end

function interpret_view(view::IntrinsicSizeView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    # Render the child view using its intrinsic size
    intrinsic_width, intrinsic_height = measure(view.child)
    final_width = min(intrinsic_width, width)
    final_height = min(intrinsic_height, height)

    interpret_view(view.child, x, y, final_width, final_height, projection_matrix)
end

function detect_click(view::IntrinsicSizeView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32)
    # Forward the click detection to the child
    detect_click(view.child, mouse_state, x, y, width, height)
end

function measure(view::IntrinsicSizeView)::Tuple{Float32,Float32}
    return measure(view.child)
end

function preferred_size(view::IntrinsicSizeView)::Bool
    return true
end