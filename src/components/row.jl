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

function interpret_view(view::RowView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    # Get the layout for the immediate children
    child_layouts = apply_layout(view, x, y, width, height)

    # Render each child using the calculated layout
    for (child, (child_x, child_y, child_width, child_height)) in zip(view.children, child_layouts)
        interpret_view(child, child_x, child_y, child_width, child_height, projection_matrix)
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