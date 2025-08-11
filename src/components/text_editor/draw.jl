"""
Draw the cursor at the specified position.
"""
function draw_cursor(
    cursor::CursorPosition,
    line_text::AbstractString,
    font,
    x::Float32,
    y::Float32,
    size_px::Int,
    projection_matrix,
    cursor_color::Vec4{Float32}=Vec4{Float32}(1.0f0, 1.0f0, 1.0f0, 0.8f0)  # Default to white
)
    # Calculate cursor x position
    if cursor.column <= 1
        cursor_x = x
    else
        # Safely get text before cursor using character indexing
        try
            # Convert to string and use character-aware slicing
            line_str = string(line_text)
            char_count = min(cursor.column - 1, length(line_str))

            # Use character indexing instead of byte indexing
            if char_count <= 0
                text_before_cursor = ""
            else
                # Safe character-based substring
                chars = collect(line_str)
                if char_count <= length(chars)
                    text_before_cursor = join(chars[1:char_count])
                else
                    text_before_cursor = line_str
                end
            end

            cursor_x = x + measure_word_width(font, text_before_cursor, size_px)
        catch e
            # Fallback: if character indexing fails, position cursor at start
            @warn "Error calculating cursor position, using fallback" exception = (e, catch_backtrace())
            cursor_x = x
        end
    end

    # Draw cursor as a vertical line
    cursor_width = 2.0f0
    cursor_height = Float32(size_px)

    # Create cursor rectangle
    cursor_vertices = generate_rectangle_vertices(cursor_x, y - cursor_height + 4, cursor_width, cursor_height)
    draw_rectangle(cursor_vertices, cursor_color, projection_matrix)
end

"""
Draw selection background for a line of text.
"""
function draw_selection_background(
    line_text::AbstractString,
    line_number::Int,
    selection_start::CursorPosition,
    selection_end::CursorPosition,
    font,
    x::Float32,
    y::Float32,
    size_px::Int,
    projection_matrix,
    selection_color::Vec4{Float32}=Vec4{Float32}(0.3f0, 0.5f0, 0.8f0, 0.4f0)  # Default blue selection
)
    # Normalize selection positions
    start_pos, end_pos = selection_start, selection_end
    if compare_cursor_positions(start_pos, end_pos) > 0
        start_pos, end_pos = end_pos, start_pos
    end

    # Check if this line is within the selection range
    if line_number < start_pos.line || line_number > end_pos.line
        return  # Line not in selection
    end

    line_str = string(line_text)
    chars = collect(line_str)
    line_height = Float32(size_px)

    # Determine start and end columns for this line
    start_col = (line_number == start_pos.line) ? start_pos.column : 1
    end_col = (line_number == end_pos.line) ? end_pos.column : length(chars) + 1

    # Calculate start x position
    start_x = x
    if start_col > 1
        text_before_start = join(chars[1:min(start_col - 1, length(chars))])
        start_x += measure_word_width(font, text_before_start, size_px)
    end

    # Calculate selection width
    selection_width = 0.0f0
    if end_col > start_col
        selected_chars_end = min(end_col - 1, length(chars))
        if selected_chars_end >= start_col
            selected_text = join(chars[start_col:selected_chars_end])
            selection_width = measure_word_width(font, selected_text, size_px)
        end
    end

    # Draw selection background rectangle
    if selection_width > 0
        selection_vertices = generate_rectangle_vertices(start_x, y - line_height + 4, selection_width, line_height)
        draw_rectangle(selection_vertices, selection_color, projection_matrix)
    end
end

