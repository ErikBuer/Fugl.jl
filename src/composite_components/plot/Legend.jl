"""
Legend component for displaying plot element labels with visual representations.
"""
struct LegendView <: AbstractView
    elements::Vector{AbstractPlotElement}
    text_style::TextStyle
    spacing::Float32
    item_height::Float32
    sample_width::Float32  # Width of the visual sample (line/marker)
    on_click::Union{Function,Nothing}  # Callback(index::Int) when legend item clicked
end

function Legend(
    elements::Vector{<:AbstractPlotElement};
    text_style::TextStyle=TextStyle(size_px=12, color=Vec4f(0.9, 0.9, 0.95, 1.0)),
    spacing::Float32=8.0f0,
    item_height::Float32=20.0f0,
    sample_width::Float32=30.0f0,
    on_click::Union{Function,Nothing}=nothing
)
    return LegendView(elements, text_style, spacing, item_height, sample_width, on_click)
end

function measure(view::LegendView)::Tuple{Float32,Float32}
    # Filter elements that have labels
    labeled_elements = filter(e -> !isempty(e.label), view.elements)

    if isempty(labeled_elements)
        return (0.0f0, 0.0f0)
    end

    # Calculate maximum text width
    max_text_width = 0.0f0
    for element in labeled_elements
        text_view = Text(element.label, style=view.text_style)
        text_measure = measure(text_view)
        max_text_width = max(max_text_width, text_measure[1])
    end

    # Total width = sample width + spacing + text width
    total_width = view.sample_width + view.spacing + max_text_width

    # Total height = (number of items * item_height) + (spacing between items)
    num_items = length(labeled_elements)
    total_height = num_items * view.item_height + (num_items - 1) * view.spacing

    return (total_width, total_height)
end

function apply_layout(view::LegendView, x::Float32, y::Float32, width::Float32, height::Float32)
    return (x, y, width, height)
end

function interpret_view(view::LegendView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32)
    # Filter elements that have labels
    labeled_elements = filter(e -> !isempty(e.label), view.elements)

    if isempty(labeled_elements)
        return
    end

    current_y = y + height  # Start from top

    for element in labeled_elements
        # Calculate item position (move down for each item)
        item_y = current_y - view.item_height

        # Render the visual sample for this element
        sample_center_x = x + view.sample_width / 2.0f0
        sample_center_y = item_y + view.item_height / 2.0f0

        render_legend_sample(element, sample_center_x, sample_center_y, view.sample_width, view.item_height, projection_matrix)

        # Render the label text (with reduced opacity if muted)
        text_x = x + view.sample_width + view.spacing
        text_style = if element.muted
            # Reduce opacity for muted elements
            muted_color = Vec4f(view.text_style.color[1], view.text_style.color[2], view.text_style.color[3], 0.4f0)
            TextStyle(size_px=view.text_style.size_px, color=muted_color)
        else
            view.text_style
        end
        text_view = Text(element.label, style=text_style)
        text_measure = measure(text_view)

        # Center text vertically within item height
        text_y = item_y + (view.item_height - text_measure[2]) / 2.0f0

        interpret_view(text_view, text_x, text_y, text_measure[1], text_measure[2], projection_matrix, mouse_x, mouse_y)

        # Move to next item
        current_y -= (view.item_height + view.spacing)
    end
end

function detect_click(view::LegendView, input_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32, parent_z::Int32)::Union{ClickResult,Nothing}
    # If no click callback, don't handle clicks
    if view.on_click === nothing
        return nothing
    end

    # Check if left mouse button was clicked
    if !input_state.was_clicked[LeftButton]
        return nothing
    end

    mouse_x = input_state.x
    mouse_y = input_state.y

    # Check if click is within legend bounds
    if mouse_x < x || mouse_x > x + width || mouse_y < y || mouse_y > y + height
        return nothing
    end

    # Filter elements that have labels
    labeled_elements = filter(e -> !isempty(e.label), view.elements)

    if isempty(labeled_elements)
        return nothing
    end

    current_y = y + height  # Start from top

    for (i, element) in enumerate(labeled_elements)
        # Calculate item position
        item_y = current_y - view.item_height

        # Check if click is within this item's bounds
        if mouse_y >= item_y && mouse_y <= item_y + view.item_height
            # Find the actual index in the original elements array
            actual_index = findfirst(e -> e === element, view.elements)
            if actual_index !== nothing
                # Return ClickResult to consume the click and call the callback
                return ClickResult(Int32(parent_z + 1), () -> view.on_click(actual_index))
            end
        end

        # Move to next item
        current_y -= (view.item_height + view.spacing)
    end

    return nothing
end

# Render visual samples for different element types
function render_legend_sample(element::LinePlotElement, center_x::Float32, center_y::Float32, sample_width::Float32, sample_height::Float32, projection_matrix::Mat4{Float32})
    # Draw a short line segment in the element's style
    line_start_x = center_x - sample_width / 3.0f0
    line_end_x = center_x + sample_width / 3.0f0

    # Apply reduced opacity if muted
    color = element.muted ? Vec4f(element.color[1], element.color[2], element.color[3], element.color[4] * 0.4f0) : element.color

    # Create a simple line batch
    batch = LineBatch()
    line_points = [Point2f(line_start_x, center_y), Point2f(line_end_x, center_y)]
    add_line!(batch, line_points, color, element.width, element.line_style)
    draw_lines(batch, projection_matrix)
end

function render_legend_sample(element::ScatterPlotElement, center_x::Float32, center_y::Float32, sample_width::Float32, sample_height::Float32, projection_matrix::Mat4{Float32})
    # Apply reduced opacity if muted
    fill_color = element.muted ? Vec4f(element.fill_color[1], element.fill_color[2], element.fill_color[3], element.fill_color[4] * 0.4f0) : element.fill_color
    border_color = element.muted ? Vec4f(element.border_color[1], element.border_color[2], element.border_color[3], element.border_color[4] * 0.4f0) : element.border_color

    # Draw a single marker in the element's style
    batch = MarkerBatch()
    add_marker!(batch, Point2f(center_x, center_y), element.marker_size, fill_color, border_color, element.border_width, element.marker_type)
    draw_markers(batch, projection_matrix)
end

function render_legend_sample(element::StemPlotElement, center_x::Float32, center_y::Float32, sample_width::Float32, sample_height::Float32, projection_matrix::Mat4{Float32})
    # Apply reduced opacity if muted
    fill_color = element.muted ? Vec4f(element.fill_color[1], element.fill_color[2], element.fill_color[3], element.fill_color[4] * 0.4f0) : element.fill_color
    border_color = element.muted ? Vec4f(element.border_color[1], element.border_color[2], element.border_color[3], element.border_color[4] * 0.4f0) : element.border_color

    # Draw just the marker (as specified in requirements)
    batch = MarkerBatch()
    add_marker!(batch, Point2f(center_x, center_y), element.marker_size, fill_color, border_color, element.border_width, element.marker_type)
    draw_markers(batch, projection_matrix)
end

# Fallback for other element types
function render_legend_sample(element::AbstractPlotElement, center_x::Float32, center_y::Float32, sample_width::Float32, sample_height::Float32, projection_matrix::Mat4{Float32})
    # Default: draw nothing
end
