struct RowView <: AbstractView
    children::Vector{AbstractView}
    padding::Float32 # Padding around the row
    spacing::Float32 # Space between children
    on_click::Function
end

function Row(children::Vector{<:AbstractView}; padding=10.0, spacing=10.0, on_click::Function=() -> nothing)
    return RowView(children, padding, spacing, on_click)
end

@inline function Row(children::AbstractView...; padding=10.0, spacing=10.0, on_click::Function=() -> nothing)
    return RowView(collect(AbstractView, children), padding, spacing, on_click)
end

function apply_layout(view::RowView, x::Float32, y::Float32, width::Float32, height::Float32)
    # Adjust the layout area to account for the global padding
    padded_x = x + view.padding
    padded_y = y + view.padding
    padded_width = width - 2 * view.padding
    padded_height = height - 2 * view.padding

    # Handle the case where there are no children
    if isempty(view.children)
        return []
    end

    # Calculate the width available for each child
    total_spacing = (length(view.children) - 1) * view.spacing
    child_width = (padded_width - total_spacing) / length(view.children)
    child_x = padded_x
    child_layouts = []

    # Calculate layout for each child
    for child in view.children
        push!(child_layouts, (child_x, padded_y, child_width, padded_height))
        child_x += child_width + view.spacing
    end

    return child_layouts
end

function interpret_view(view::RowView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32)
    # Get the layout for the immediate children
    child_layouts = apply_layout(view, x, y, width, height)

    # Render each child using the calculated layout
    for (child, (child_x, child_y, child_width, child_height)) in zip(view.children, child_layouts)
        interpret_view(child, child_x, child_y, child_width, child_height, projection_matrix, mouse_x, mouse_y)
    end
end

function detect_click(view::RowView, mouse_state::InputState, x::AbstractFloat, y::AbstractFloat, width::AbstractFloat, height::AbstractFloat)
    if inside_component(view, x, y, width, height, mouse_state.x, mouse_state.y)
        if mouse_state.was_clicked[LeftButton]
            view.on_click()  # Call the on_click function of the clicked child
        end
    end

    # Get the layout for the immediate children
    child_layouts = apply_layout(view, x, y, width, height)

    # Traverse each child and check for clicks
    for (child, (child_x, child_y, child_width, child_height)) in zip(view.children, child_layouts)
        # Recursively check the child
        detect_click(child, mouse_state, child_x, child_y, child_width, child_height)
    end
end

function measure(view::RowView)::Tuple{Float32,Float32}
    if isempty(view.children)
        return (0f0, 0f0)
    end
    child_sizes = [measure(child) for child in view.children]
    total_width = sum(s[1] for s in child_sizes) + (length(view.children) - 1) * view.spacing
    max_height = maximum(s[2] for s in child_sizes)
    total_width += 2 * view.padding
    max_height += 2 * view.padding
    return (total_width, max_height)
end

"""
Measure the width of the component when constrained by available height.
"""
function measure_width(view::RowView, available_height::Float32)::Float32
    if isempty(view.children)
        return 2 * view.padding  # Just padding if no children
    end

    # Account for padding in available height
    padded_height = available_height - 2 * view.padding

    child_widths = [measure_width(child, padded_height) for child in view.children]
    total_width = sum(s for s in child_widths) + (length(view.children) - 1) * view.spacing
    total_width += 2 * view.padding
    return total_width

end

"""
Measure the height of the component when constrained by available height.
"""
function measure_height(view::RowView, available_width::Float32)::Float32
    if isempty(view.children)
        return 2 * view.padding  # Just padding if no children
    end

    # Account for padding in available height
    padded_width = available_width - 2 * view.padding

    width_per_child = (padded_width - (length(view.children) - 1) * view.spacing) / length(view.children)

    child_heights = [measure_height(child, width_per_child) for child in view.children]
    max_height = maximum(child_heights)
    max_height += 2 * view.padding
    return max_height
end