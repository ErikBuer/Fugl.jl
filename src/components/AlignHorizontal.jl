struct AlignHorizontalView <: AbstractView
    child::SizedView
    alignment::Symbol  # :left, :center, :right
end

"""
    AlignHorizontal(child::AbstractView, alignment::Symbol)

Aligns a sized child component horizontally within its container.

# Arguments
- `child`: A AbstractView component that has intrinsic dimensions
- `alignment`: Horizontal alignment (:left, :center, :right)

# Example
```julia
AlignHorizontal(IntrinsicSize(Image("logo.png")), :left)
AlignHorizontal(FixedSize(Text("Hello"), 100.0f0, 50.0f0), :right)
```
"""
function AlignHorizontal(child::AbstractView, alignment::Symbol=:center)
    if alignment ∉ (:left, :center, :right)
        error("Invalid horizontal alignment: $alignment. Must be :left, :center, or :right")
    end
    return AlignHorizontalView(child, alignment)
end

@inline AlignLeft(child::AbstractView) = AlignHorizontal(child, :left)
@inline AlignCenter(child::AbstractView) = AlignHorizontal(child, :center)
@inline AlignRight(child::AbstractView) = AlignHorizontal(child, :right)

function measure(view::AlignHorizontalView)::Tuple{Float32,Float32}
    # Return the child's preferred size
    return measure(view.child)
end

function measure_width(view::AlignHorizontalView, available_height::Float32)::Float32
    # Measure the child's width at the given height
    child_width = measure_width(view.child, available_height)
    return child_width
end

function measure_height(view::AlignHorizontalView, available_width::Float32)::Float32
    # Measure the child's height at the given width
    child_height = measure_height(view.child, available_width)
    return child_height
end

function apply_layout(view::AlignHorizontalView, x::Float32, y::Float32, width::Float32, height::Float32)
    # Get the child's preferred size
    child_width, child_height = measure(view.child)

    # Use the child's preferred size, but constrain to available space
    final_child_width = min(child_width, width)
    final_child_height = min(child_height, height)

    # Calculate vertical centering (always center vertically)
    child_y = y + (height - final_child_height) / 2

    # Calculate horizontal alignment
    if view.alignment == :left
        child_x = x
    elseif view.alignment == :center
        child_x = x + (width - final_child_width) / 2
    else  # :right
        child_x = x + width - final_child_width
    end

    return (child_x, child_y, final_child_width, final_child_height)
end

function interpret_view(view::AlignHorizontalView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, cursor_position::Point2f, window_size::Size)
    # Get the child's layout
    child_x, child_y, child_width, child_height = apply_layout(view, x, y, width, height)

    # Render the child
    interpret_view(view.child, child_x, child_y, child_width, child_height, projection_matrix, cursor_position, window_size)
end

function detect_click(view::AlignHorizontalView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32, parent_z::Int32)::Union{ClickResult,Nothing}
    # Get the child's layout and forward click detection
    child_x, child_y, child_width, child_height = apply_layout(view, x, y, width, height)
    return detect_click(view.child, mouse_state, child_x, child_y, child_width, child_height, parent_z)
end

"""
Check if the component has a preferred width.
"""
function preferred_width(view::AlignHorizontalView)::Bool
    return preferred_width(view.child)
end

"""
Check if the component has a preferred height.
"""
function preferred_height(view::AlignHorizontalView)::Bool
    return preferred_height(view.child)
end