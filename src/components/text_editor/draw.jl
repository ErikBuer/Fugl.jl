"""
Calculate which portion of a text line is visible given horizontal scroll and viewport width.
Returns (visible_text, start_x_offset) where:
- visible_text is the substring that should be drawn
- start_x_offset is how much to shift the drawing position
"""
function calculate_visible_text(line::AbstractString, font, size_px::Int, scroll_x::Float32, visible_width::Float32)
    if isempty(line)
        return ("", 0.0f0)
    end

    chars = collect(line)
    if isempty(chars)
        return ("", 0.0f0)
    end

    # Find the first visible character
    current_x = 0.0f0
    start_char = 1

    for i in 1:length(chars)
        char_width = measure_word_width(font, string(chars[i]), size_px)
        if current_x + char_width > scroll_x
            start_char = i
            break
        end
        current_x += char_width
    end

    # Find the last visible character
    end_char = start_char
    width_so_far = current_x

    for i in start_char:length(chars)
        char_width = measure_word_width(font, string(chars[i]), size_px)
        if width_so_far - scroll_x > visible_width
            break
        end
        end_char = i
        width_so_far += char_width
    end

    # Calculate the x offset for drawing (how much of the first character is cut off)
    start_x_offset = scroll_x - current_x

    # Extract visible substring
    visible_text = if start_char <= end_char && end_char <= length(chars)
        join(chars[start_char:end_char])
    else
        ""
    end

    return (visible_text, start_x_offset)
end

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
    selection_color::Vec4{Float32}=Vec4{Float32}(0.3f0, 0.5f0, 0.8f0, 0.4f0);  # Default blue selection
    visible_start_x::Float32=-Inf32,
    visible_end_x::Float32=Inf32
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

    # Clip selection to visible bounds
    if selection_width > 0
        selection_end_x = start_x + selection_width

        # Clip the selection rectangle to visible bounds
        clipped_start_x = max(start_x, visible_start_x)
        clipped_end_x = min(selection_end_x, visible_end_x)
        clipped_width = max(0.0f0, clipped_end_x - clipped_start_x)

        # Draw selection background rectangle only if visible
        if clipped_width > 0
            selection_vertices = generate_rectangle_vertices(clipped_start_x, y - line_height + 4, clipped_width, line_height)
            draw_rectangle(selection_vertices, selection_color, projection_matrix)
        end
    end
end

