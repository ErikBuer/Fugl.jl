struct IntrinsicRowView <: AbstractView
    children::Vector{AbstractView}
    spacing::Float32 # Space between children
    reduce_spacing_on_overflow::Bool # If true, reduce spacing before clipping when space is tight
    on_click::Function
end

function IntrinsicRow(children::Vector{<:AbstractView}; spacing=10.0, reduce_spacing_on_overflow=true, on_click::Function=() -> nothing)
    return IntrinsicRowView(children, spacing, reduce_spacing_on_overflow, on_click)
end

@inline function IntrinsicRow(children::AbstractView...; spacing=10.0, reduce_spacing_on_overflow=true, on_click::Function=() -> nothing)
    return IntrinsicRowView(collect(AbstractView, children), spacing, reduce_spacing_on_overflow, on_click)
end

function apply_layout(view::IntrinsicRowView, x::Float32, y::Float32, width::Float32, height::Float32)
    n = length(view.children)

    # First pass: gather intrinsic widths
    intrinsic_widths = Float32[]
    is_intrinsic = Bool[]
    for child in view.children
        if preferred_width(child)
            push!(intrinsic_widths, measure_width(child, height))
            push!(is_intrinsic, true)
        else
            push!(intrinsic_widths, 0f0)
            push!(is_intrinsic, false)
        end
    end
    total_intrinsic_width = sum(intrinsic_widths)
    n_flexible = count(!, is_intrinsic)

    # Calculate spacing - reduce if needed when reduce_spacing_on_overflow is true
    effective_spacing = view.spacing
    if view.reduce_spacing_on_overflow && n > 1
        available_width = width
        total_spacing_needed = (n - 1) * view.spacing
        total_content_width = total_intrinsic_width + total_spacing_needed

        # If content doesn't fit with full spacing, reduce spacing
        if total_content_width > available_width
            max_possible_spacing = max(0f0, (available_width - total_intrinsic_width) / (n - 1))
            effective_spacing = min(view.spacing, max_possible_spacing)
        end
    end

    total_spacing = (n - 1) * effective_spacing
    remaining_width = max(0f0, width - total_spacing - total_intrinsic_width)
    flexible_width = n_flexible > 0 ? remaining_width / n_flexible : 0f0

    # Second pass: assign layouts
    child_x = x
    child_layouts = []
    for (i, child) in enumerate(view.children)
        child_width = is_intrinsic[i] ? intrinsic_widths[i] : flexible_width
        push!(child_layouts, (child_x, y, child_width, height))
        child_x += child_width + effective_spacing
    end

    return child_layouts
end

function interpret_view(view::IntrinsicRowView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, cursor_position::Point2f, window_size::Size)
    child_layouts = apply_layout(view, x, y, width, height)
    for (child, (child_x, child_y, child_width, child_height)) in zip(view.children, child_layouts)
        interpret_view(child, child_x, child_y, child_width, child_height, projection_matrix, cursor_position, window_size)
    end
end

"""
Detect clicks on the IntrinsicRow and its children.
The method returns the click result with the highest z-height.
"""
function detect_click(view::IntrinsicRowView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32, parent_z::Int32)::Union{ClickResult,Nothing}
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

    if !inside_component(view, x, y, width, height, Float32(mouse_state.x), Float32(mouse_state.y))
        return nothing
    end

    if mouse_state.was_clicked[LeftButton]
        return ClickResult(Int32(parent_z + 1), () -> view.on_click())  # Call the on_click function of the row
    end

    return nothing
end

function measure(view::IntrinsicRowView)::Tuple{Float32,Float32}
    if isempty(view.children)
        return (0f0, 0f0)
    end
    child_sizes = [measure(child) for child in view.children]
    max_height = maximum(s[2] for s in child_sizes)
    total_width = sum(s[1] for s in child_sizes) + (length(view.children) - 1) * view.spacing

    return (total_width, max_height)
end

"""
Measure the width of the component when constrained by available height.
"""
function measure_width(view::IntrinsicRowView, available_height::Float32)::Float32
    if isempty(view.children)
        return 0.0f0
    end

    # Measure each child's width given the available height
    child_widths = [measure_width(child, available_height) for child in view.children]

    # Total width is sum of child widths plus spacing
    total_width = sum(child_widths) + (length(view.children) - 1) * view.spacing

    return total_width
end

"""
Measure the height of the component when constrained by available width.
"""
function measure_height(view::IntrinsicRowView, available_width::Float32)::Float32
    if isempty(view.children)
        return 0.0f0
    end

    # Only take max over children with a fixed preferred height
    preferred_heights = [measure_height(child, available_width) for child in view.children if preferred_height(child)]

    # For a row, height is the maximum height of any preferred child
    max_height = isempty(preferred_heights) ? 0f0 : maximum(preferred_heights)

    return max_height
end

"""
Preferred width - IntrinsicRow has preferred width only if ALL children do.
If any child is flexible (fills remaining space), the row's total width is
unknown at measure time and must be allocated by the parent layout.
"""
function preferred_width(view::IntrinsicRowView)::Bool
    return all(preferred_width(child) for child in view.children)
end

"""
Preferred height if any of the children has.
"""
function preferred_height(view::IntrinsicRowView)::Bool
    return any(preferred_height(child) for child in view.children)
end