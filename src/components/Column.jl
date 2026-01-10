struct ColumnView <: AbstractView
    children::Vector{AbstractView}
    padding::Float32 # Padding around the column
    spacing::Float32 # Space between children
    on_click::Function
end

function Column(children::Vector{<:AbstractView}; padding=10.0, spacing=10.0, on_click::Function=() -> nothing)
    return ColumnView(children, padding, spacing, on_click)
end

@inline function Column(children::AbstractView...; padding=10.0, spacing=10.0, on_click::Function=() -> nothing)
    return ColumnView(collect(AbstractView, children), padding, spacing, on_click)
end

function apply_layout(view::ColumnView, x::Float32, y::Float32, width::Float32, height::Float32)
    # Adjust the layout area to account for the global padding
    padded_x = x + view.padding
    padded_y = y + view.padding
    padded_width = width - 2 * view.padding
    padded_height = height - 2 * view.padding

    # Handle the case where there are no children
    if isempty(view.children)
        return []
    end

    # Calculate the height available for each child
    total_spacing = (length(view.children) - 1) * view.spacing
    child_height = (padded_height - total_spacing) / length(view.children)
    child_y = padded_y
    child_layouts = []

    # Calculate layout for each child
    for child in view.children
        push!(child_layouts, (padded_x, child_y, padded_width, child_height))
        child_y += child_height + view.spacing
    end

    return child_layouts
end

function interpret_view(view::ColumnView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32)
    # Get the layout for the immediate children
    child_layouts = apply_layout(view, x, y, width, height)

    # Render each child using the calculated layout
    for (child, (child_x, child_y, child_width, child_height)) in zip(view.children, child_layouts)
        interpret_view(child, child_x, child_y, child_width, child_height, projection_matrix, mouse_x, mouse_y)
    end
end

"""
Detect clicks on the Column and its children.
The method returns the click result with the highest z-height.
"""
function detect_click(view::ColumnView, mouse_state::InputState, x::AbstractFloat, y::AbstractFloat, width::AbstractFloat, height::AbstractFloat, parent_z::Int32)::Union{ClickResult,Nothing}
    # Get the layout for the immediate children
    child_layouts = apply_layout(view, x, y, width, height)

    click_result::Union{ClickResult,Nothing} = nothing

    # Traverse each child and check for clicks
    for (child, (child_x, child_y, child_width, child_height)) in zip(view.children, child_layouts)
        # Recursively check the child
        child_click_result = detect_click(child, mouse_state, child_x, child_y, child_width, child_height, Int32(parent_z + 1))

        if child_click_result === nothing
            continue
        end

        if click_result === nothing
            click_result = child_click_result
            continue
        end

        if click_result.z_height < child_click_result.z_height
            click_result = child_click_result
        end
    end

    if click_result !== nothing
        return click_result
    end

    if !inside_component(view, x, y, width, height, mouse_state.x, mouse_state.y)
        return nothing
    end

    if mouse_state.was_clicked[LeftButton]
        return ClickResult(Int32(parent_z + 1), () -> view.on_click())  # Call the on_click function of the column
    end

    return nothing
end

function measure(view::ColumnView)::Tuple{Float32,Float32}
    if isempty(view.children)
        return (0f0, 0f0)
    end
    child_sizes = [measure(child) for child in view.children]
    max_width = maximum(s[1] for s in child_sizes)
    total_height = sum(s[2] for s in child_sizes) + (length(view.children) - 1) * view.spacing
    max_width += 2 * view.padding
    total_height += 2 * view.padding
    return (max_width, total_height)
end

"""
Measure the width of the column when constrained by available height.
"""
function measure_width(view::ColumnView, available_height::Float32)::Float32
    if isempty(view.children)
        return 2 * view.padding  # Just padding if no children
    end

    # Account for padding in available height
    padded_height = available_height - 2 * view.padding

    height_per_child = (padded_height - (length(view.children) - 1) * view.spacing) / length(view.children)

    child_widths = [measure_width(child, height_per_child) for child in view.children]
    max_width = maximum(child_widths)
    max_width += 2 * view.padding
    return max_width
end

"""
Measure the height of the column when constrained by available width.
"""
function measure_height(view::ColumnView, available_width::Float32)::Float32
    if isempty(view.children)
        return 2 * view.padding  # Just padding if no children
    end

    # Account for padding in available width
    padded_width = available_width - 2 * view.padding

    child_heights = [measure_height(child, padded_width) for child in view.children]
    total_height = sum(child_heights) + (length(view.children) - 1) * view.spacing
    total_height += 2 * view.padding
    return total_height
end