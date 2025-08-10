include("font_cache.jl")
include("utilities.jl")
include("text_style.jl")
include("glyph_atlas.jl")
include("glyph_batch.jl")
include("draw.jl")

struct TextView <: AbstractView
    text::String
    style::TextStyle
    horizontal_align::Symbol  # :left, :center, :right
    vertical_align::Symbol    # :top, :middle, :bottom
end

function Text(text::String; style=TextStyle(), horizontal_align=:center, vertical_align=:middle)
    return TextView(text, style, horizontal_align, vertical_align)
end

"""
    measure(view::TextView)::Tuple{Float32,Float32}

Assumes all text is rendered in a single line.
"""
function measure(view::TextView)::Tuple{Float32,Float32}
    font = view.style.font
    size_px = view.style.size_px

    text_width = measure_word_width(font, view.text, size_px)
    text_height = Float32(size_px) + 2.0
    text_width = text_width + 2.0

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
    lines = String[]
    current_line = ""
    current_width = 0.0f0

    space_width = measure_word_width(font, " ", size_px)

    for word in words
        # Measure the width of the word
        word_width = measure_word_width(font, word, size_px)

        if current_line == ""
            if word_width > width
                # Word too long for any line, but we have to place it
                current_line = word
                current_width = word_width
            else
                current_line = word
                current_width = word_width
            end
        else
            # Check if word + space fits on current line
            if current_width + space_width + word_width > width
                # Move to a new line
                push!(lines, current_line)
                current_line = word
                current_width = word_width
            else
                current_line *= " " * word
                current_width += space_width + word_width
            end
        end
    end

    # Push the last line
    push!(lines, current_line)

    # Calculate total text height
    total_height = length(lines) * size_px

    # Calculate vertical alignment offset
    vertical_offset = calculate_text_vertical_offset(height, total_height, view.vertical_align)

    # Collect positions for all lines for batched rendering
    x_positions = Float32[]
    y_positions = Float32[]

    current_y = y + vertical_offset
    for line in lines
        # Calculate horizontal alignment offset
        line_width = measure_word_width(font, line, size_px)
        horizontal_offset = calculate_horizontal_offset(width, line_width, view.horizontal_align)

        push!(x_positions, x + horizontal_offset)
        push!(y_positions, current_y)

        # Move to the next line
        current_y += size_px
    end

    # Render all lines in a single batched call for maximum performance
    # This replaces individual draw_text calls with one optimized batch
    draw_multiline_text_batched(
        font,                # Font face
        lines,               # All lines of text
        x_positions,         # X positions for each line
        y_positions,         # Y positions for each line
        size_px,             # Text size
        projection_matrix,   # Projection matrix
        color                # Text color
    )
end