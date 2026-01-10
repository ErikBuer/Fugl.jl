include("table_state.jl")
include("table_style.jl")

"""
    Table(headers, data; kwargs...)

Create a table component with column headers and row data.

# Arguments
- `headers::Vector{String}`: Column header names
- `data::Vector{Vector{String}}`: Table data as rows of strings
- `style::TableStyle=TableStyle()`: Table styling options
- `state::TableState=TableState()`: Table state for column widths and sizing
- `on_cell_click::Function=(row, col) -> nothing`: Callback for cell clicks
- `on_state_change::Function=(new_state) -> nothing`: Callback for state changes

# Example
```julia
headers = ["Name", "Age", "City"]
data = [
    ["Alice", "25", "New York"],
    ["Bob", "30", "London"],
    ["Carol", "28", "Tokyo"]
]
table = Table(headers, data)
```
"""
function Table(
    headers::Vector{String},
    data::Vector{Vector{String}};
    style::TableStyle=TableStyle(),
    state::TableState=TableState(),
    on_cell_click::Function=(row, col) -> nothing,
    on_state_change::Function=(new_state) -> nothing
)
    return TableView(headers, data, style, state, on_cell_click, on_state_change)
end

"""
    wrap_cell_text(text, font, size_px, available_width, max_rows)

Wrap text for a table cell, respecting max_rows limit and clipping if necessary.
Returns a vector of strings representing the lines to display.
max_rows = 0 means no wrapping (single line with character-level clipping and ellipsis).
"""
function wrap_cell_text(text::String, font, size_px::Int, available_width::Float32, max_rows::Int)::Vector{String}
    if max_rows == 0
        # No wrapping - clip at character level with ellipsis
        return [clip_text_with_ellipsis(text, font, size_px, available_width)]
    end

    # Split text into words for wrapping
    words = split(text, " ")
    lines = String[]
    current_line = ""
    current_width = 0.0f0
    space_width = measure_word_width_cached(font, " ", size_px)

    for word in words
        word_width = measure_word_width_cached(font, word, size_px)

        if current_line == ""
            # First word on a line
            current_line = word
            current_width = word_width
        else
            # Check if word + space fits on current line
            if current_width + space_width + word_width > available_width
                # Move to new line
                push!(lines, current_line)

                # Check if we've reached max rows
                if length(lines) >= max_rows
                    # Clip the last line with ellipsis if there are more words
                    remaining_words = words[(findfirst(x -> x == word, words)):end]
                    remaining_text = join(remaining_words, " ")
                    if !isempty(remaining_text)
                        lines[end] = clip_text_with_ellipsis(lines[end] * " " * remaining_text, font, size_px, available_width)
                    end
                    break  # Stop processing more words
                end

                current_line = word
                current_width = word_width
            else
                current_line *= " " * word
                current_width += space_width + word_width
            end
        end
    end

    # Push the last line if we haven't exceeded max rows
    if current_line != "" && length(lines) < max_rows
        push!(lines, current_line)
    end

    return lines
end

"""
    clip_text_with_ellipsis(text, font, size_px, available_width)

Clip text at character level to fit within available width, adding "..." if clipped.
"""
function clip_text_with_ellipsis(text::String, font, size_px::Int, available_width::Float32)::String
    # Measure the full text width
    full_width = measure_word_width_cached(font, text, size_px)

    if full_width <= available_width
        # Text fits completely
        return text
    end

    # Text needs clipping - measure ellipsis width
    ellipsis = "..."
    ellipsis_width = measure_word_width_cached(font, ellipsis, size_px)

    # Available width for actual text (minus ellipsis)
    text_width_budget = available_width - ellipsis_width

    if text_width_budget <= 0
        # Not enough space even for ellipsis, return empty or just dots
        return available_width > ellipsis_width ? ellipsis : ""
    end

    # Find the maximum number of characters that fit
    current_width = 0.0f0
    char_count = 0

    for char in text
        char_width = measure_word_width_cached(font, string(char), size_px)

        if current_width + char_width > text_width_budget
            break
        end

        current_width += char_width
        char_count += 1
    end

    # Return clipped text with ellipsis
    if char_count == 0
        return ellipsis
    else
        return text[1:char_count] * ellipsis
    end
end

function measure(view::TableView)::Tuple{Float32,Float32}
    # Calculate minimum width based on headers and content
    num_cols = length(view.headers)
    num_rows = length(view.data)

    if num_cols == 0
        return (0.0f0, 0.0f0)
    end

    # Estimate minimum column widths based on header text
    min_col_widths = Float32[]
    for header in view.headers
        header_width = measure_word_width_cached(view.style.header_text_style.font, header, view.style.header_text_style.size_px)
        push!(min_col_widths, header_width + 2 * view.style.cell_padding)
    end

    # Check data rows for wider content
    for row in view.data
        for (col_idx, cell) in enumerate(row)
            if col_idx <= length(min_col_widths)
                cell_width = measure_word_width_cached(view.style.cell_text_style.font, cell, view.style.cell_text_style.size_px)
                min_col_widths[col_idx] = max(min_col_widths[col_idx], cell_width + 2 * view.style.cell_padding)
            end
        end
    end

    total_width = sum(min_col_widths)

    # Add grid lines if enabled
    if view.style.show_grid
        total_width += (num_cols - 1) * view.style.grid_width
    end

    # Add border width
    total_width += 2 * view.style.border_width

    # Calculate total height
    total_height = view.style.header_height + num_rows * view.style.cell_height

    # Add grid lines if enabled
    if view.style.show_grid
        total_height += num_rows * view.style.grid_width  # Horizontal grid lines
    end

    # Add border height
    total_height += 2 * view.style.border_width

    return (total_width, total_height)
end

function interpret_view(view::TableView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32)
    num_cols = length(view.headers)
    num_rows = length(view.data)

    if num_cols == 0
        return
    end

    # Calculate column widths using state
    border_width = view.style.border_width
    grid_width = view.style.show_grid ? view.style.grid_width : 0.0f0
    available_width = width - 2 * border_width

    # Get effective column widths (from state or auto-calculated)
    col_widths = get_effective_column_widths(view, available_width)

    # Check if we need to auto-calculate widths on first render
    if isnothing(view.state.column_widths) && view.state.auto_size
        # Auto-calculate and update state on first render
        calculate_and_update_column_widths!(view, available_width)
        # Use the newly calculated widths
        col_widths = get_effective_column_widths(view, available_width)
    end

    # Draw outer border using multiple rectangles (top, bottom, left, right)
    if border_width > 0
        # Top border
        top_border_vertices = [
            Point2f(x, y + height - border_width),
            Point2f(x, y + height),
            Point2f(x + width, y + height),
            Point2f(x + width, y + height - border_width)
        ]
        draw_rectangle(top_border_vertices, view.style.border_color, projection_matrix)

        # Bottom border
        bottom_border_vertices = [
            Point2f(x, y),
            Point2f(x, y + border_width),
            Point2f(x + width, y + border_width),
            Point2f(x + width, y)
        ]
        draw_rectangle(bottom_border_vertices, view.style.border_color, projection_matrix)

        # Left border
        left_border_vertices = [
            Point2f(x, y),
            Point2f(x, y + height),
            Point2f(x + border_width, y + height),
            Point2f(x + border_width, y)
        ]
        draw_rectangle(left_border_vertices, view.style.border_color, projection_matrix)

        # Right border
        right_border_vertices = [
            Point2f(x + width - border_width, y),
            Point2f(x + width - border_width, y + height),
            Point2f(x + width, y + height),
            Point2f(x + width, y)
        ]
        draw_rectangle(right_border_vertices, view.style.border_color, projection_matrix)
    end

    # Current drawing position
    current_y = y + border_width

    # Draw header row
    header_y = current_y
    current_x = x + border_width

    # Draw header background - fill the entire width between borders
    if view.style.header_background_color[4] > 0.0  # Only if not transparent
        header_bg_vertices = [
            Point2f(current_x, header_y),
            Point2f(current_x, header_y + view.style.header_height),
            Point2f(x + width - border_width, header_y + view.style.header_height),
            Point2f(x + width - border_width, header_y)
        ]
        draw_rectangle(header_bg_vertices, view.style.header_background_color, projection_matrix)
    end

    # Draw header text
    current_x = x + border_width
    for (col_idx, header) in enumerate(view.headers)
        col_width = col_widths[col_idx]

        # Create text view for header
        header_text = Text(header,
            style=view.style.header_text_style,
            horizontal_align=:center,
            vertical_align=:middle,
            wrap_text=false
        )

        interpret_view(header_text,
            current_x + view.style.cell_padding,
            header_y,
            col_width - 2 * view.style.cell_padding,
            view.style.header_height,
            projection_matrix,
            mouse_x, mouse_y
        )

        # Move to next column
        current_x += col_width + grid_width
    end

    current_y += view.style.header_height

    # Draw horizontal grid line after header if enabled
    if view.style.show_grid
        line_vertices = [
            Point2f(x + border_width, current_y),
            Point2f(x + border_width, current_y + grid_width),
            Point2f(x + width - border_width, current_y + grid_width),
            Point2f(x + width - border_width, current_y)
        ]
        draw_rectangle(line_vertices, view.style.grid_color, projection_matrix)
        current_y += grid_width
    end

    # Fill entire remaining table area with default background color first
    remaining_area_height = y + height - border_width - current_y
    if remaining_area_height > 0
        fill_bg_vertices = [
            Point2f(x + border_width, current_y),
            Point2f(x + border_width, y + height - border_width),
            Point2f(x + width - border_width, y + height - border_width),
            Point2f(x + width - border_width, current_y)
        ]
        draw_rectangle(fill_bg_vertices, view.style.cell_background_color, projection_matrix)
    end

    # Draw data rows
    for (row_idx, row) in enumerate(view.data)
        row_y = current_y

        # Determine background color (alternating rows)
        row_bg_color = if row_idx % 2 == 1
            view.style.cell_background_color
        else
            view.style.cell_alternate_background_color
        end

        # Draw cell background for this specific row (will override the fill)
        if row_bg_color[4] > 0.0  # Only if not transparent
            row_bg_vertices = [
                Point2f(x + border_width, row_y),
                Point2f(x + border_width, row_y + view.style.cell_height),
                Point2f(x + width - border_width, row_y + view.style.cell_height),
                Point2f(x + width - border_width, row_y)
            ]
            draw_rectangle(row_bg_vertices, row_bg_color, projection_matrix)
        end

        # Draw cells in this row
        current_x = x + border_width
        for (col_idx, cell_text) in enumerate(row)
            if col_idx <= num_cols  # Don't exceed number of columns
                col_width = col_widths[col_idx]

                # Calculate available width for text (minus padding)
                available_text_width = col_width - 2 * view.style.cell_padding

                # Wrap the cell text based on table settings
                wrapped_lines = wrap_cell_text(
                    cell_text,
                    view.style.cell_text_style.font,
                    view.style.cell_text_style.size_px,
                    available_text_width,
                    view.style.max_wrapped_rows
                )

                # Render each line of wrapped text
                line_height = Float32(view.style.cell_text_style.size_px)
                for (line_idx, line) in enumerate(wrapped_lines)
                    # Calculate vertical position for this line
                    line_y = row_y + (line_idx - 1) * line_height

                    # Only render if the line fits within the cell height
                    if line_y + line_height <= row_y + view.style.cell_height
                        # Create text view for this line
                        line_text_view = Text(line,
                            style=view.style.cell_text_style,
                            horizontal_align=:left,
                            vertical_align=:top,  # Use top alignment for multi-line
                            wrap_text=false  # Already wrapped, don't wrap again
                        )

                        interpret_view(line_text_view,
                            current_x + view.style.cell_padding,
                            line_y,
                            available_text_width,
                            min(line_height, view.style.cell_height - (line_y - row_y)),
                            projection_matrix,
                            mouse_x, mouse_y
                        )
                    end
                end

                # Move to next column
                current_x += col_width + grid_width
            end
        end

        current_y += view.style.cell_height

        # Draw horizontal grid line after row if enabled
        if view.style.show_grid && row_idx < num_rows  # Don't draw after last row
            line_vertices = [
                Point2f(x + border_width, current_y),
                Point2f(x + border_width, current_y + grid_width),
                Point2f(x + width - border_width, current_y + grid_width),
                Point2f(x + width - border_width, current_y)
            ]
            draw_rectangle(line_vertices, view.style.grid_color, projection_matrix)
            current_y += grid_width
        end
    end

    # Draw vertical grid lines if enabled
    if view.style.show_grid
        current_x = x + border_width
        for col_idx in 1:(num_cols-1)
            # Move to the end of current column
            current_x += col_widths[col_idx]

            # Draw grid line
            line_vertices = [
                Point2f(current_x, y + border_width),
                Point2f(current_x + grid_width, y + border_width),
                Point2f(current_x + grid_width, y + height - border_width),
                Point2f(current_x, y + height - border_width)
            ]
            draw_rectangle(line_vertices, view.style.grid_color, projection_matrix)

            # Move past the grid line for next iteration
            current_x += grid_width
        end
    end
end

function detect_click(view::TableView, input_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32, parent_z::Int32)::Union{ClickResult,Nothing}
    if !input_state.was_clicked[LeftButton]
        return
    end

    mouse_x = Float32(input_state.x) - x
    mouse_y = Float32(input_state.y) - y

    num_cols = length(view.headers)
    num_rows = length(view.data)

    if num_cols == 0 || mouse_x < 0 || mouse_y < 0 || mouse_x > width || mouse_y > height
        return
    end

    # Calculate dimensions
    border_width = view.style.border_width
    grid_width = view.style.show_grid ? view.style.grid_width : 0.0f0
    available_width = width - 2 * border_width

    # Get column widths
    col_widths = get_effective_column_widths(view, available_width)

    # Adjust mouse coordinates for border
    adjusted_mouse_x = mouse_x - border_width
    adjusted_mouse_y = mouse_y - border_width

    # Check if click is in header
    if adjusted_mouse_y >= 0 && adjusted_mouse_y <= view.style.header_height
        # Click in header - could add header click handling here
        return
    end

    # Check if click is in data area
    data_start_y = view.style.header_height + (view.style.show_grid ? grid_width : 0.0f0)

    if adjusted_mouse_y < data_start_y
        return  # Click in header separator
    end

    # Calculate which row was clicked
    data_mouse_y = adjusted_mouse_y - data_start_y
    row_height_with_grid = view.style.cell_height + (view.style.show_grid ? grid_width : 0.0f0)

    row_idx = Int(floor(data_mouse_y / row_height_with_grid)) + 1

    if row_idx > num_rows || row_idx < 1
        return
    end

    # Calculate which column was clicked using variable column widths
    current_x = 0.0f0
    col_idx = 0

    for (i, col_width) in enumerate(col_widths)
        if adjusted_mouse_x >= current_x && adjusted_mouse_x < current_x + col_width
            col_idx = i
            break
        end
        current_x += col_width + grid_width
    end

    if col_idx == 0 || col_idx > num_cols
        return  # Click in grid line or outside
    end

    # Call the cell click callback
    on_cell_click() = view.on_cell_click(row_idx, col_idx)
    return ClickResult(Int32(parent_z + 1), on_cell_click)
end

"""
    calculate_column_widths(view::TableView, available_width::Float32)::Vector{Float32}

Calculate optimal column widths based on content and available space.
Uses a simple algorithm that:
1. Calculates minimum width needed for each column based on content
2. If total minimum width < available width, distributes extra space proportionally
3. If total minimum width > available width, scales all columns down proportionally
"""
function calculate_column_widths(view::TableView, available_width::Float32)::Vector{Float32}
    num_cols = length(view.headers)

    if num_cols == 0
        return Float32[]
    end

    # Calculate minimum width needed for each column
    min_col_widths = Float32[]

    # Start with header widths
    for header in view.headers
        header_width = measure_word_width_cached(view.style.header_text_style.font, header, view.style.header_text_style.size_px)
        push!(min_col_widths, header_width + 2 * view.style.cell_padding)
    end

    # Check data rows for wider content
    for row in view.data
        for (col_idx, cell) in enumerate(row)
            if col_idx <= length(min_col_widths)
                cell_width = measure_word_width_cached(view.style.cell_text_style.font, cell, view.style.cell_text_style.size_px)
                min_col_widths[col_idx] = max(min_col_widths[col_idx], cell_width + 2 * view.style.cell_padding)
            end
        end
    end

    # Account for grid lines in available width
    grid_width = view.style.show_grid ? view.style.grid_width : 0.0f0
    content_available_width = available_width - (num_cols - 1) * grid_width

    total_min_width = sum(min_col_widths)

    if total_min_width <= content_available_width
        # We have extra space - distribute proportionally based on content
        if total_min_width > 0
            scale_factor = content_available_width / total_min_width
            return min_col_widths .* scale_factor
        else
            # All columns are empty, distribute equally
            equal_width = content_available_width / num_cols
            return fill(equal_width, num_cols)
        end
    else
        # Not enough space - scale down proportionally (content may be clipped)
        scale_factor = content_available_width / total_min_width
        return min_col_widths .* scale_factor
    end
end

"""
    get_effective_column_widths(view::TableView, available_width::Float32)::Vector{Float32}

Get effective column widths for rendering.
Priority: state.column_widths -> auto-calculated widths
"""
function get_effective_column_widths(view::TableView, available_width::Float32)::Vector{Float32}
    # Priority 1: Explicit column widths from state
    if !isnothing(view.state.column_widths) && length(view.state.column_widths) == length(view.headers)
        return view.state.column_widths
    end

    # Priority 2: Auto-calculate based on content
    return calculate_column_widths(view, available_width)
end

"""
    calculate_and_update_column_widths!(view::TableView, available_width::Float32)

Calculate new column widths and update the table state via callback.
This function can be called by the user when they want to recalculate column sizing.
"""
function calculate_and_update_column_widths!(view::TableView, available_width::Float32)
    new_widths = calculate_column_widths(view, available_width)

    # Create new state with calculated widths
    new_state = TableState(view.state;
        column_widths=new_widths,
        cache_id=rand(UInt64)  # Generate new cache ID for state change
    )

    # Notify via callback
    view.on_state_change(new_state)
end
