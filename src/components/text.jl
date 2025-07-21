struct TextView <: AbstractView
    text::String
    style::TextStyle
    horizontal_align::Symbol  # :left, :center, :right
    vertical_align::Symbol    # :top, :middle, :bottom
end

function Text(text::String; style=TextStyle(), horizontal_align=:center, vertical_align=:middle)
    return TextView(text, style, horizontal_align, vertical_align)
end

function measure(view::TextView)::Tuple{Float32,Float32}
    font = view.style.font
    size_px = view.style.size_px

    # Measure the width and height of the text
    text_width = measure_word_width(font, view.text, size_px)

    # Add generous padding to ensure text fits properly when using IntrinsicSize
    # Height should account for font metrics, ascenders/descenders, and container padding
    text_height = Float32(size_px) * 1.2
    text_width = text_width + 2 * size_px

    return (text_width, text_height)
end

function apply_layout(view::TextView, x::Float32, y::Float32, width::Float32, height::Float32)
    # Text layout is simple: it occupies the entire area provided
    return (x, y, width, height)
end

function interpret_view(view::TextView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    # Extract style properties
    font = view.style.font
    size_px = view.style.size_px
    color = view.style.color

    # Split text into words
    words = split(view.text, " ")

    # Calculate line breaks
    lines = []
    current_line = ""
    current_width = 0.0f0

    for word in words
        # Measure the width of the word, including a space
        word_width = measure_word_width(font, word, size_px)
        space_width = measure_word_width(font, " ", size_px)

        # Check if the word fits in the current line
        if current_width + word_width + space_width > width
            # Move to a new line
            push!(lines, current_line)
            current_line = word
            current_width = word_width
        else
            if current_line == ""
                current_line = word
            else
                current_line *= " " * word
            end
        end
    end

    # Push the last line
    push!(lines, current_line)

    # Calculate total text height
    total_height = length(lines) * size_px

    # Calculate vertical alignment offset
    vertical_offset = calculate_text_vertical_offset(height, total_height, view.vertical_align)

    # Render each line
    current_y = y + vertical_offset
    for line in lines
        # Calculate horizontal alignment offset
        line_width = measure_word_width(font, line, size_px)
        horizontal_offset = calculate_horizontal_offset(width, line_width, view.horizontal_align)

        # Render the line
        draw_text(
            font,                # Font face
            line,                # Text string
            x + horizontal_offset, # X position
            current_y,           # Y position
            size_px,             # Text size
            projection_matrix,   # Projection matrix
            color                # Text color
        )

        # Move to the next line
        current_y += size_px
    end
end