struct FixedSizeView <: SizedView
    child::AbstractView
    width::Float32
    height::Float32
end

struct FixedWidthView <: SizedView
    child::AbstractView
    width::Float32
end

struct FixedHeightView <: SizedView
    child::AbstractView
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

"""
    FixedWidth(child::AbstractView, width::Real)

Creates a view that has a fixed width but uses the child's intrinsic height.
"""
function FixedWidth(child::AbstractView, width::Real)::FixedWidthView
    FixedWidthView(child, Float32(width))
end

"""
    FixedHeight(child::AbstractView, height::Real)

Creates a view that has a fixed height but uses the child's intrinsic width.
"""
function FixedHeight(child::AbstractView, height::Real)::FixedHeightView
    FixedHeightView(child, Float32(height))
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

# FixedWidth implementation
function apply_layout(view::FixedWidthView, x::Float32, y::Float32, width::Float32, height::Float32)
    final_width = min(view.width, width)
    return (x, y, final_width, height)
end

function interpret_view(view::FixedWidthView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    final_width = min(view.width, width)
    interpret_view(view.child, x, y, final_width, height, projection_matrix)
end

function detect_click(view::FixedWidthView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32)
    final_width = min(view.width, width)
    detect_click(view.child, mouse_state, x, y, final_width, height)
end

function measure(view::FixedWidthView)::Tuple{Float32,Float32}
    child_width, child_height = measure(view.child)
    return (view.width, child_height)
end

function preferred_width(view::FixedWidthView)::Bool
    return true
end

function preferred_height(view::FixedWidthView)::Bool
    return preferred_height(view.child)
end

# FixedHeight implementation
function apply_layout(view::FixedHeightView, x::Float32, y::Float32, width::Float32, height::Float32)
    final_height = min(view.height, height)
    return (x, y, width, final_height)
end

function interpret_view(view::FixedHeightView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    final_height = min(view.height, height)
    interpret_view(view.child, x, y, width, final_height, projection_matrix)
end

function detect_click(view::FixedHeightView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32)
    final_height = min(view.height, height)
    detect_click(view.child, mouse_state, x, y, width, final_height)
end

function measure(view::FixedHeightView)::Tuple{Float32,Float32}
    child_width, child_height = measure(view.child)
    return (child_width, view.height)
end

function preferred_width(view::FixedHeightView)::Bool
    return preferred_width(view.child)
end

function preferred_height(view::FixedHeightView)::Bool
    return true
end