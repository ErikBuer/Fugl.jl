struct IntrinsicRowView <: AbstractView
    children::Vector{AbstractView}
    padding::Float32 # Padding around the row
    spacing::Float32 # Space between children
    on_click::Function
end

function IntrinsicRow(children::Vector{<:AbstractView}; padding=10.0, spacing=10.0, on_click::Function=() -> nothing)
    return IntrinsicRowView(children, padding, spacing, on_click)
end

function apply_layout(view::IntrinsicRowView, x, y, width, height)
    padded_x = x + view.padding
    padded_y = y + view.padding
    padded_height = height - 2 * view.padding
    n = length(view.children)
    total_spacing = (n - 1) * view.spacing

    # First pass: gather intrinsic widths
    intrinsic_widths = Float32[]
    is_intrinsic = Bool[]
    for child in view.children
        if preferred_width(child)
            push!(intrinsic_widths, measure(child)[1])
            push!(is_intrinsic, true)
        else
            push!(intrinsic_widths, 0f0)
            push!(is_intrinsic, false)
        end
    end
    total_intrinsic_width = sum(intrinsic_widths)
    n_flexible = count(!, is_intrinsic)
    remaining_width = max(0f0, width - 2 * view.padding - total_spacing - total_intrinsic_width)
    flexible_width = n_flexible > 0 ? remaining_width / n_flexible : 0f0

    # Second pass: assign layouts
    child_x = padded_x
    child_layouts = []
    for (i, child) in enumerate(view.children)
        child_width = is_intrinsic[i] ? intrinsic_widths[i] : flexible_width
        push!(child_layouts, (child_x, padded_y, child_width, padded_height))
        child_x += child_width + view.spacing
    end

    return child_layouts
end

function interpret_view(view::IntrinsicRowView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    child_layouts = apply_layout(view, x, y, width, height)
    for (child, (child_x, child_y, child_width, child_height)) in zip(view.children, child_layouts)
        interpret_view(child, child_x, child_y, child_width, child_height, projection_matrix)
    end
end

function detect_click(view::IntrinsicRowView, mouse_state::InputState, x::AbstractFloat, y::AbstractFloat, width::AbstractFloat, height::AbstractFloat)
    if inside_component(view, x, y, width, height, mouse_state.x, mouse_state.y)
        if mouse_state.was_clicked[LeftButton]
            view.on_click()
        end
    end
    child_layouts = apply_layout(view, x, y, width, height)
    for (child, (child_x, child_y, child_width, child_height)) in zip(view.children, child_layouts)
        detect_click(child, mouse_state, child_x, child_y, child_width, child_height)
    end
end

function measure(view::IntrinsicRowView)::Tuple{Float32,Float32}
    if isempty(view.children)
        return (0f0, 0f0)
    end
    child_sizes = [measure(child) for child in view.children]
    max_height = maximum(s[2] for s in child_sizes)
    total_width = sum(s[1] for s in child_sizes) + (length(view.children) - 1) * view.spacing
    total_width += 2 * view.padding
    return (total_width, max_height + 2 * view.padding)
end