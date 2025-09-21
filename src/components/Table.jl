"""
Table component for displaying tabular data with headers and rows.

The Table component provides:
- Column headers with customizable text and styling
- Dynamic number of rows based on data
- Cell-based text content
- Customizable styling for headers, cells, borders, and spacing
- Grid lines between rows and columns

Usage:
    headers = ["Name", "Age", "City"]
    data = [
        ["Alice", "25", "New York"],
        ["Bob", "30", "London"],
        ["Carol", "28", "Tokyo"]
    ]
    Table(headers, data)
"""

struct TableStyle
    # Header styling
    header_background_color::Vec4f
    header_text_style::TextStyle
    header_height::Float32

    # Cell styling
    cell_background_color::Vec4f
    cell_alternate_background_color::Vec4f  # Color for alternating rows
    cell_text_style::TextStyle
    cell_height::Float32

    # Text wrapping and clipping
    max_wrapped_rows::Int  # 0 = no wrapping (single row), >0 = max number of wrapped rows

    # Grid styling
    show_grid::Bool
    grid_color::Vec4f
    grid_width::Float32

    # Padding and spacing
    cell_padding::Float32

    # Border styling
    border_color::Vec4f
    border_width::Float32
end

function TableStyle(;
    header_background_color::Vec4f=Vec4f(0.9, 0.9, 0.9, 1.0),
    header_text_style::TextStyle=TextStyle(size_px=14, color=Vec4f(0.0, 0.0, 0.0, 1.0)),
    header_height::Float32=30.0f0,
    cell_background_color::Vec4f=Vec4f(1.0, 1.0, 1.0, 1.0),
    cell_alternate_background_color::Vec4f=Vec4f(0.95, 0.95, 0.95, 1.0),
    cell_text_style::TextStyle=TextStyle(size_px=12, color=Vec4f(0.0, 0.0, 0.0, 1.0)),
    cell_height::Float32=25.0f0,
    max_wrapped_rows::Int=0,
    show_grid::Bool=true,
    grid_color::Vec4f=Vec4f(0.7, 0.7, 0.7, 1.0),
    grid_width::Float32=1.0f0, cell_padding::Float32=8.0f0, border_color::Vec4f=Vec4f(0.5, 0.5, 0.5, 1.0),
    border_width::Float32=1.0f0
)
    return TableStyle(
        header_background_color, header_text_style, header_height,
        cell_background_color, cell_alternate_background_color, cell_text_style, cell_height,
        max_wrapped_rows,
        show_grid, grid_color, grid_width,
        cell_padding,
        border_color, border_width
    )
end

struct TableView <: AbstractView
    headers::Vector{String}
    data::Vector{Vector{String}}  # Vector of rows, each row is a vector of cell strings
    style::TableStyle
    on_cell_click::Function  # Callback for cell clicks: (row_index, col_index) -> nothing
end

"""
    Table(headers, data; kwargs...)

Create a table component with column headers and row data.

# Arguments
- `headers::Vector{String}`: Column header names
- `data::Vector{Vector{String}}`: Table data as rows of strings
- `style::TableStyle=TableStyle()`: Table styling options
- `on_cell_click::Function=(row, col) -> nothing`: Callback for cell clicks

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
    on_cell_click::Function=(row, col) -> nothing
)
    return TableView(headers, data, style, on_cell_click)
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

function interpret_view(view::TableView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    num_cols = length(view.headers)
    num_rows = length(view.data)

    if num_cols == 0
        return
    end

    # Calculate column widths (equal distribution for now)
    border_width = view.style.border_width
    grid_width = view.style.show_grid ? view.style.grid_width : 0.0f0

    available_width = width - 2 * border_width - (num_cols - 1) * grid_width
    col_width = available_width / num_cols

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
    for (col_idx, header) in enumerate(view.headers)
        cell_x = current_x + (col_idx - 1) * (col_width + grid_width)

        # Create text view for header
        header_text = Text(header,
            style=view.style.header_text_style,
            horizontal_align=:center,
            vertical_align=:middle,
            wrap_text=false
        )

        interpret_view(header_text,
            cell_x + view.style.cell_padding,
            header_y,
            col_width - 2 * view.style.cell_padding,
            view.style.header_height,
            projection_matrix
        )
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
                cell_x = current_x + (col_idx - 1) * (col_width + grid_width)

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
                            cell_x + view.style.cell_padding,
                            line_y,
                            available_text_width,
                            min(line_height, view.style.cell_height - (line_y - row_y)),
                            projection_matrix
                        )
                    end
                end
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
            line_x = current_x + col_idx * col_width + (col_idx - 1) * grid_width
            line_vertices = [
                Point2f(line_x, y + border_width),
                Point2f(line_x + grid_width, y + border_width),
                Point2f(line_x + grid_width, y + height - border_width),
                Point2f(line_x, y + height - border_width)
            ]
            draw_rectangle(line_vertices, view.style.grid_color, projection_matrix)
        end
    end
end

function detect_click(view::TableView, input_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32)
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
    available_width = width - 2 * border_width - (num_cols - 1) * grid_width
    col_width = available_width / num_cols

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

    # Calculate which column was clicked
    col_width_with_grid = col_width + grid_width
    col_idx = Int(floor(adjusted_mouse_x / col_width_with_grid)) + 1

    if col_idx > num_cols || col_idx < 1
        return
    end

    # Call the cell click callback
    view.on_cell_click(row_idx, col_idx)
end
