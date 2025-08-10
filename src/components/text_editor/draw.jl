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

