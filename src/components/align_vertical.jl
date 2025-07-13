struct AlignVerticalView <: AbstractView
    child::SizedView
    alignment::Symbol  # :top, :center, :bottom
end

"""
    AlignVertical(child::SizedView, alignment::Symbol)

Aligns a sized child component vertically within its container.

# Arguments
- `child`: A SizedView component that has intrinsic dimensions
- `alignment`: Vertical alignment (:top, :center, :bottom)

# Example
```julia
AlignVertical(IntrinsicSize(Image("logo.png")), :top)
AlignVertical(FixedSize(Text("Hello"), 100.0f0, 50.0f0), :center)
```
"""
function AlignVertical(child::SizedView, alignment::Symbol=:center)
    if alignment ∉ (:top, :center, :bottom)
        error("Invalid vertical alignment: $alignment. Must be :top, :center, or :bottom")
    end
    return AlignVerticalView(child, alignment)
end

function measure(view::AlignVerticalView)::Tuple{Float32,Float32}
    # Return the child's preferred size
    return measure(view.child)
end

function apply_layout(view::AlignVerticalView, x::Float32, y::Float32, width::Float32, height::Float32)
    # Get the child's preferred size
    child_width, child_height = measure(view.child)

    # Use the child's preferred width, but allow it to use available width if smaller
    final_child_width = min(child_width, width)
    final_child_height = min(child_height, height)    # Calculate horizontal centering (always center horizontally)
    child_x = x + (width - final_child_width) / 2

    # Calculate vertical alignment
    if view.alignment == :top
        child_y = y
    elseif view.alignment == :center
        child_y = y + (height - final_child_height) / 2
    else  # :bottom
        child_y = y + height - final_child_height
    end

    return (child_x, child_y, final_child_width, final_child_height)
end

function interpret_view(view::AlignVerticalView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    # Get the child's layout
    child_x, child_y, child_width, child_height = apply_layout(view, x, y, width, height)

    # Render the child
    interpret_view(view.child, child_x, child_y, child_width, child_height, projection_matrix)
end

function detect_click(view::AlignVerticalView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32)
    # Get the child's layout and forward click detection
    child_x, child_y, child_width, child_height = apply_layout(view, x, y, width, height)
    detect_click(view.child, mouse_state, child_x, child_y, child_width, child_height)
end
