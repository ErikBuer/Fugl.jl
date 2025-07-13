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
    projection_matrix
)
    # Calculate cursor x position
    if cursor.column <= 1
        cursor_x = x
    else
        # Measure text up to cursor position
        text_before_cursor = line_text[1:min(cursor.column - 1, length(line_text))]
        cursor_x = x + measure_word_width(font, text_before_cursor, size_px)
    end

    # Draw cursor as a vertical line
    cursor_color = Vec4{Float32}(1.0f0, 1.0f0, 1.0f0, 0.8f0)  # Semi-transparent white
    cursor_width = 2.0f0
    cursor_height = Float32(size_px)

    # Create cursor rectangle
    cursor_vertices = generate_rectangle_vertices(cursor_x, y - cursor_height + 4, cursor_width, cursor_height)
    draw_rectangle(cursor_vertices, cursor_color, projection_matrix)
end

