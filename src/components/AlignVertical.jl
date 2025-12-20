struct AlignVerticalView <: AbstractView
    child::SizedView
    alignment::Symbol  # :top, :middle, :bottom
end

"""
    AlignVertical(child::SizedView, alignment::Symbol)

Aligns a sized child component vertically within its container.

# Arguments
- `child`: A SizedView component that has intrinsic dimensions
- `alignment`: Vertical alignment (:top, :middle, :bottom)

# Example
```julia
AlignVertical(IntrinsicSize(Image("logo.png")), :top)
AlignVertical(FixedSize(Text("Hello"), 100.0f0, 50.0f0), :middle)
```
"""
function AlignVertical(child::SizedView, alignment::Symbol=:middle)
    if alignment ∉ (:top, :middle, :bottom)
        error("Invalid vertical alignment: $alignment. Must be :top, :middle, or :bottom")
    end
    return AlignVerticalView(child, alignment)
end

@inline AlignTop(child::SizedView) = AlignVertical(child, :top)
@inline AlignMiddle(child::SizedView) = AlignVertical(child, :middle)
@inline AlignBottom(child::SizedView) = AlignVertical(child, :bottom)

function measure(view::AlignVerticalView)::Tuple{Float32,Float32}
    # Return the child's preferred size
    return measure(view.child)
end

function measure_width(view::AlignVerticalView, available_height::Float32)::Float32
    # Measure the child's width at the given height
    child_width = measure_width(view.child, available_height)
    return child_width
end

function measure_height(view::AlignVerticalView, available_width::Float32)::Float32
    # Measure the child's height at the given width
    child_height = measure_height(view.child, available_width)
    return child_height
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
    elseif view.alignment == :middle
        child_y = y + (height - final_child_height) / 2
    else  # :bottom
        child_y = y + height - final_child_height
    end

    return (child_x, child_y, final_child_width, final_child_height)
end

function interpret_view(view::AlignVerticalView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32)
    # Get the child's layout
    child_x, child_y, child_width, child_height = apply_layout(view, x, y, width, height)

    # Render the child
    interpret_view(view.child, child_x, child_y, child_width, child_height, projection_matrix, mouse_x, mouse_y)
end

function detect_click(view::AlignVerticalView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32)
    # Get the child's layout and forward click detection
    child_x, child_y, child_width, child_height = apply_layout(view, x, y, width, height)
    detect_click(view.child, mouse_state, child_x, child_y, child_width, child_height)
end
