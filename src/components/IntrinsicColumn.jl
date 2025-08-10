struct IntrinsicColumnView <: AbstractView
    children::Vector{AbstractView}
    padding::Float32 # Padding around the column
    spacing::Float32 # Space between children
    on_click::Function
end

function IntrinsicColumn(children::Vector{<:AbstractView}; padding=10.0, spacing=10.0, on_click::Function=() -> nothing)
    return IntrinsicColumnView(children, padding, spacing, on_click)
end

function apply_layout(view::IntrinsicColumnView, x, y, width, height)
    padded_x = x + view.padding
    padded_y = y + view.padding
    padded_width = width - 2 * view.padding
    n = length(view.children)
    total_spacing = (n - 1) * view.spacing

    # First pass: gather intrinsic heights
    intrinsic_heights = Float32[]
    is_intrinsic = Bool[]
    for child in view.children
        if preferred_height(child)
            push!(intrinsic_heights, measure(child)[2])
            push!(is_intrinsic, true)
        else
            push!(intrinsic_heights, 0f0)
            push!(is_intrinsic, false)
        end
    end
    total_intrinsic_height = sum(intrinsic_heights)
    n_flexible = count(!, is_intrinsic)
    remaining_height = max(0f0, height - 2 * view.padding - total_spacing - total_intrinsic_height)
    flexible_height = n_flexible > 0 ? remaining_height / n_flexible : 0f0

    # Second pass: assign layouts
    child_y = padded_y
    child_layouts = []
    for (i, child) in enumerate(view.children)
        child_height = is_intrinsic[i] ? intrinsic_heights[i] : flexible_height
        push!(child_layouts, (padded_x, child_y, padded_width, child_height))
        child_y += child_height + view.spacing
    end

    return child_layouts
end


function interpret_view(view::IntrinsicColumnView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    # Get the layout for the immediate children
    child_layouts = apply_layout(view, x, y, width, height)

    # Render each child using the calculated layout
    for (child, (child_x, child_y, child_width, child_height)) in zip(view.children, child_layouts)
        interpret_view(child, child_x, child_y, child_width, child_height, projection_matrix)
    end
end

function detect_click(view::IntrinsicColumnView, mouse_state::InputState, x::AbstractFloat, y::AbstractFloat, width::AbstractFloat, height::AbstractFloat)
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

function measure(view::IntrinsicColumnView)::Tuple{Float32,Float32}
    # The width is the max of all children's intrinsic widths, height is sum of heights + spacing + padding
    if isempty(view.children)
        return (0f0, 0f0)
    end
    child_sizes = [measure(child) for child in view.children]
    max_width = maximum(s[1] for s in child_sizes)
    total_height = sum(s[2] for s in child_sizes) + (length(view.children) - 1) * view.spacing
    total_height += 2 * view.padding
    return (max_width + 2 * view.padding, total_height)
end