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
    font = get_font(view.style)
    size_points = view.style.size_points

    # Original behavior - measure as single line (will wrap based on container width)
    # text_width = measure_word_width(font, view.text, size_points)
    text_width = measure_word_width_cached(font, view.text, size_points)
    text_height = Float32(size_points) * 1.3f0 + 2.0f0
    text_width = text_width + 2.0

    return (text_width, text_height)
end

"""
Measure the width of the text when constrained by available height.
"""
function measure_width(view::TextView, available_height::Float32)::Float32
    # Text width is not constrained by height, so return the full measured width

    font = get_font(view.style)
    size_points = view.style.size_points

    # Original behavior - measure as single line (will wrap based on container width)
    text_width = measure_word_width_cached(font, view.text, size_points)
    text_width = text_width + 2.0

    return text_width
end

function measure_height(view::TextView, available_width::Float32)::Float32
    font = get_font(view.style)
    size_points = view.style.size_points
    line_height = Float32(size_points)

    # Non-wrapping text is always a single line
    if !view.wrap_text
        return line_height * 1.3f0 + 2.0f0
    end

    words = split(view.text, " ")
    lines = String[]
    current_line = ""
    current_width = 0.0f0
    space_width = measure_word_width_cached(font, " ", size_points)

    for word in words
        word_width = measure_word_width_cached(font, word, size_points)

        if current_line == ""
            current_line = word
            current_width = word_width
        else
            if current_width + space_width + word_width > available_width
                push!(lines, current_line)
                current_line = word
                current_width = word_width
            else
                current_line *= " " * word
                current_width += space_width + word_width
            end
        end
    end

    push!(lines, current_line)

    return length(lines) * line_height + line_height * 0.3f0 + 2.0f0
end

function apply_layout(view::TextView, x::Float32, y::Float32, width::Float32, height::Float32)
    # Text layout is simple: it occupies the entire area provided
    return (x, y, width, height)
end

function interpret_view(view::TextView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix_points::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32)
    # Extract style properties
    font = get_font(view.style)
    size_points = view.style.size_points
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

        space_width = measure_word_width_cached(font, " ", size_points)

        for word in words
            # Measure the width of the word
            word_width = measure_word_width_cached(font, word, size_points)

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

    # Calculate total text height (include descender space: ~30% of em below baseline)
    line_height = Float32(size_points)
    total_height = length(lines) * line_height + line_height * 0.3f0

    # Calculate vertical alignment offset with proper multi-line support
    vertical_offset = calculate_text_vertical_offset(height, total_height, line_height, view.vertical_align)

    # Collect positions for all lines for batched rendering
    x_positions = Float32[]
    y_positions = Float32[]

    # Start from the top of the text block (y + vertical_offset gives us the baseline of the first line)
    current_y = y + vertical_offset
    for line in lines
        # Calculate horizontal alignment offset
        line_width = measure_word_width_cached(font, line, size_points)
        horizontal_offset = calculate_horizontal_offset(width, line_width, view.horizontal_align)

        # Snap positions to pixel boundaries for crisp text rendering
        snapped_x = round(x + horizontal_offset)
        snapped_y = round(current_y)

        push!(x_positions, Float32(snapped_x))
        push!(y_positions, Float32(snapped_y))

        # Move to the next line using consistent line height
        current_y += line_height
    end

    # Render all lines in a single batched call for maximum performance.
    # Pass the component bounds so glyphs that are not fully inside are culled.
    draw_multiline_text_batched(
        font,                     # Font face
        lines,                    # All lines of text
        x_positions,              # X positions for each line
        y_positions,              # Y positions for each line
        size_points,              # Text size
        projection_matrix_points, # Projection matrix
        color;                    # Text color
        clip_bounds_points=Rectangle(x, y, width, height)
    )
end

"""
Text prefers its intrinsic width based on content.
"""
function preferred_width(view::TextView)::Bool
    return true
end

"""
Text prefers its intrinsic height based on font size and line count.
"""
function preferred_height(view::TextView)::Bool
    return true
end