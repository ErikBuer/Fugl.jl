struct CheckBoxStyle
    size::Float32                    # Size of the checkbox square
    background_color::Vec4f          # Background color when unchecked
    background_color_checked::Vec4f  # Background color when checked
    border_color::Vec4f              # Border color
    border_width::Float32            # Border width
    check_color::Vec4f               # Color of the checkmark
    corner_radius::Float32           # Corner radius for rounded checkbox
    padding::Float32                 # Padding around the checkbox
    label_style::TextStyle           # Style for the label text
end

function CheckBoxStyle(;
    size::Float32=20.0f0,
    background_color::Vec4f=Vec4f(1.0, 1.0, 1.0, 1.0),  # White background
    background_color_checked::Vec4f=Vec4f(0.2, 0.8, 0.2, 1.0),  # Green when checked
    border_color::Vec4f=Vec4f(0.6, 0.6, 0.6, 1.0),  # Gray border
    border_width::Float32=1.5f0,
    check_color::Vec4f=Vec4f(1.0, 1.0, 1.0, 1.0),  # White checkmark
    corner_radius::Float32=3.0f0,
    padding::Float32=2.0f0,
    label_style::TextStyle=TextStyle(size_px=14, color=Vec4f(0.0, 0.0, 0.0, 1.0))
)
    return CheckBoxStyle(
        size, background_color, background_color_checked,
        border_color, border_width, check_color,
        corner_radius, padding, label_style
    )
end

struct CheckBoxView <: AbstractView
    checked::Bool                    # Current checked state
    style::CheckBoxStyle            # Visual styling
    label::String                   # Optional label text
    on_change::Function             # Callback when checkbox is clicked: (new_value::Bool) -> nothing
    on_click::Function              # Additional click callback
end

"""
Create a CheckBox component

# Arguments
- `checked::Bool`: Current checked state (user should pass `checkbox_state[]`)
- `label::String`: Optional text label next to the checkbox
- `style::CheckBoxStyle`: Visual styling for the checkbox (includes label text style)
- `on_change::Function`: Callback when checkbox value changes: `(new_value::Bool) -> nothing`
- `on_click::Function`: Additional click callback

# Example
```julia
# User-managed state
checkbox_state = Ref(false)

# Create checkbox with custom style
checkbox = CheckBox(
    checkbox_state[],  # Pass current value
    label="Enable feature",
    style=CheckBoxStyle(
        size=18.0f0,
        label_style=TextStyle(size_px=16, color=Vec4f(0.2, 0.2, 0.2, 1.0))
    ),
    on_change=(new_value) -> checkbox_state[] = new_value  # User updates state
)
```
"""
function CheckBox(
    checked::Bool;
    label::String="",
    style::CheckBoxStyle=CheckBoxStyle(),
    on_change::Function=(new_value::Bool) -> nothing,
    on_click::Function=() -> nothing
)
    return CheckBoxView(checked, style, label, on_change, on_click)
end

function measure(view::CheckBoxView)::Tuple{Float32,Float32}
    checkbox_size = view.style.size + 2 * view.style.padding

    if isempty(view.label)
        return (checkbox_size, checkbox_size)
    else
        # Measure label text
        label_width = measure_word_width_cached(view.style.label_style.font, view.label, view.style.label_style.size_px)
        label_height = Float32(view.style.label_style.size_px)

        # Total width: checkbox + spacing + label
        spacing = 8.0f0  # Gap between checkbox and label
        total_width = checkbox_size + spacing + label_width
        total_height = max(checkbox_size, label_height)

        return (total_width, total_height)
    end
end

function measure_width(view::CheckBoxView, available_height::Float32)::Float32
    checkbox_size = view.style.size + 2 * view.style.padding

    if isempty(view.label)
        return checkbox_size
    else
        # Measure label text
        label_width = measure_word_width_cached(view.style.label_style.font, view.label, view.style.label_style.size_px)

        # Total width: checkbox + spacing + label
        spacing = 8.0f0
        return checkbox_size + spacing + label_width
    end
end

function measure_height(view::CheckBoxView, available_width::Float32)::Float32
    checkbox_size = view.style.size + 2 * view.style.padding

    if isempty(view.label)
        return checkbox_size
    else
        label_height = Float32(view.style.label_style.size_px)
        return max(checkbox_size, label_height)
    end
end

function apply_layout(view::CheckBoxView, x::Float32, y::Float32, width::Float32, height::Float32)
    return (x, y, width, height)
end

function interpret_view(view::CheckBoxView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    checkbox_size = view.style.size
    padding = view.style.padding

    # Position the checkbox (vertically centered)
    checkbox_x = x + padding
    checkbox_y = y + (height - checkbox_size) / 2

    # Draw checkbox background
    bg_color = view.checked ? view.style.background_color_checked : view.style.background_color

    checkbox_vertices = [
        Point2f(checkbox_x, checkbox_y),
        Point2f(checkbox_x, checkbox_y + checkbox_size),
        Point2f(checkbox_x + checkbox_size, checkbox_y + checkbox_size),
        Point2f(checkbox_x + checkbox_size, checkbox_y)
    ]

    # Draw rounded checkbox background and border
    draw_rounded_rectangle(
        checkbox_vertices,
        checkbox_size,
        checkbox_size,
        bg_color,
        view.style.border_color,
        view.style.border_width,
        view.style.corner_radius,
        projection_matrix,
        1.0f0  # Anti-aliasing width
    )

    # Draw checkmark if checked
    if view.checked
        draw_checkmark(
            checkbox_x,
            checkbox_y,
            checkbox_size,
            view.style.check_color,
            projection_matrix
        )
    end

    # Draw label if provided
    if !isempty(view.label)
        spacing = 8.0f0
        label_x = checkbox_x + checkbox_size + spacing
        label_y = y + (height + view.style.label_style.size_px) / 2  # Vertically center the text

        draw_text(
            view.style.label_style.font,
            view.label,
            label_x,
            label_y,
            view.style.label_style.size_px,
            projection_matrix,
            view.style.label_style.color
        )
    end
end

function detect_click(view::CheckBoxView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32)
    # Check if mouse is within the component bounds
    if inside_component(view, x, y, width, height, mouse_state.x, mouse_state.y)
        if get(mouse_state.was_clicked, LeftButton, false)
            # Toggle the checkbox value
            new_value = !view.checked

            # Call the change callback
            view.on_change(new_value)

            # Call additional click callback
            view.on_click()

            return true
        end
    end

    return false
end

"""
Draw a checkmark symbol inside the checkbox using the new line drawing system
"""
function draw_checkmark(x::Float32, y::Float32, size::Float32, color::Vec4f, projection_matrix::Mat4{Float32})
    # Create checkmark path (simple checkmark shape)
    # Checkmark is drawn as two line segments forming a "✓" shape

    # Scale factors for positioning the checkmark within the checkbox
    padding_factor = 0.2f0  # 20% padding from edges
    inner_size = size * (1.0f0 - 2 * padding_factor)
    start_x = x + size * padding_factor
    start_y = y + size * padding_factor

    # Checkmark coordinates (relative to inner area)
    # In UI coordinates, Y increases downward, so we need to flip the checkmark
    # First line: from left-middle to middle-bottom
    line1_start = Point2f(start_x + inner_size * 0.2f0, start_y + inner_size * 0.5f0)
    line1_end = Point2f(start_x + inner_size * 0.45f0, start_y + inner_size * 0.75f0)

    # Second line: from middle-bottom to top-right  
    line2_start = line1_end
    line2_end = Point2f(start_x + inner_size * 0.8f0, start_y + inner_size * 0.2f0)

    # Line thickness proportional to checkbox size
    line_width = size * 0.15f0

    # Draw first line segment using the new line drawing system
    draw_simple_line(
        line1_start,
        line1_end,
        color,
        line_width,
        projection_matrix;
        line_style=SOLID,
        anti_aliasing_width=1.5f0
    )

    # Draw second line segment using the new line drawing system
    draw_simple_line(
        line2_start,
        line2_end,
        color,
        line_width,
        projection_matrix;
        line_style=SOLID,
        anti_aliasing_width=1.5f0
    )
end
