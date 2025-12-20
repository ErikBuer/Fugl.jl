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
    wrap_text::Bool           # Whether to wrap text to new lines or clip
end

# Declare that we're creating a new generic function, not extending Base.Text
function Text end

"""
    Text(text::String; style=TextStyle(), horizontal_align=:center, vertical_align=:middle, wrap_text=true)

Create a Text component with the specified properties.
"""
function Text(text::String; style=TextStyle(), horizontal_align=:center, vertical_align=:middle, wrap_text=true)
    return TextView(text, style, horizontal_align, vertical_align, wrap_text)
end

"""
    measure(view::TextView)::Tuple{Float32,Float32}

Assumes text is rendered in a single line.
"""
function measure(view::TextView)::Tuple{Float32,Float32}
    font = view.style.font
    size_px = view.style.size_px

    # Original behavior - measure as single line (will wrap based on container width)
    # text_width = measure_word_width(font, view.text, size_px)
    text_width = measure_word_width_cached(font, view.text, size_px)
    text_height = Float32(size_px) + 2.0
    text_width = text_width + 2.0

    return (text_width, text_height)
end

"""
Measure the width of the text when constrained by available height.
"""
function measure_width(view::TextView, available_height::Float32)::Float32
    # Text width is not constrained by height, so return the full measured width

    font = view.style.font
    size_px = view.style.size_px

    # Original behavior - measure as single line (will wrap based on container width)
    text_width = measure_word_width_cached(font, view.text, size_px)
    text_width = text_width + 2.0

    return text_width
end

function measure_height(view::TextView, available_width::Float32)::Float32
    # Here we must account for line wrapping based on available width
    font = view.style.font
    size_px = view.style.size_px
    line_height = Float32(size_px)
    words = split(view.text, " ")
    lines = String[]
    current_line = ""
    current_width = 0.0f0
    space_width = measure_word_width_cached(font, " ", size_px)

    for word in words
        # Measure the width of the word
        word_width = measure_word_width_cached(font, word, size_px)

        if current_line == ""
            # First word on a line - always place it, even if it doesn't fit (will be clipped)
            current_line = word
            current_width = word_width
        else
            # Check if word + space fits on current line
            if current_width + space_width + word_width > available_width
                # Move to a new line
                push!(lines, current_line)
                current_line = word  # Start new line with this word
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
    total_height = length(lines) * line_height + 2.0

    return total_height
end

function apply_layout(view::TextView, x::Float32, y::Float32, width::Float32, height::Float32)
    # Text layout is simple: it occupies the entire area provided
    return (x, y, width, height)
end

function interpret_view(view::TextView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32)
    # Extract style properties
    font = view.style.font
    size_px = view.style.size_px
    color = view.style.color

    # Split text into words
    words = split(view.text, " ")

    # Calculate line breaks based on wrap_text setting
    lines = String[]

    if !view.wrap_text
        # No wrapping - treat entire text as a single line (will be clipped during rendering)
        push!(lines, view.text)
    else
        # Word wrapping logic
        current_line = ""
        current_width = 0.0f0

        space_width = measure_word_width_cached(font, " ", size_px)

        for word in words
            # Measure the width of the word
            word_width = measure_word_width_cached(font, word, size_px)

            if current_line == ""
                # First word on a line - always place it, even if it doesn't fit (will be clipped)
                current_line = word
                current_width = word_width
            else
                # Check if word + space fits on current line
                if current_width + space_width + word_width > width
                    # Move to a new line
                    push!(lines, current_line)
                    current_line = word  # Start new line with this word
                    current_width = word_width
                else
                    current_line *= " " * word
                    current_width += space_width + word_width
                end
            end
        end

        # Push the last line
        push!(lines, current_line)
    end

    # Calculate total text height
    line_height = Float32(size_px)
    total_height = length(lines) * line_height

    # Calculate vertical alignment offset with proper multi-line support
    vertical_offset = calculate_text_vertical_offset(height, total_height, line_height, view.vertical_align)

    # Collect positions for all lines for batched rendering
    x_positions = Float32[]
    y_positions = Float32[]

    # Start from the top of the text block (y + vertical_offset gives us the baseline of the first line)
    current_y = y + vertical_offset
    for line in lines
        # Calculate horizontal alignment offset
        line_width = measure_word_width_cached(font, line, size_px)
        horizontal_offset = calculate_horizontal_offset(width, line_width, view.horizontal_align)

        # Snap positions to pixel boundaries for crisp text rendering
        snapped_x = round(x + horizontal_offset)
        snapped_y = round(current_y)

        push!(x_positions, Float32(snapped_x))
        push!(y_positions, Float32(snapped_y))

        # Move to the next line using consistent line height
        current_y += line_height
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