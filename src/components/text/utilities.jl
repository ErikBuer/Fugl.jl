function create_text_texture(mat::Matrix{Float32})::GLAbstraction.Texture
    # Create a GLAbstraction.Texture
    texture = GLA.Texture(mat;
        minfilter=:linear,
        magfilter=:linear,
        x_repeat=:clamp_to_edge,
        y_repeat=:clamp_to_edge
    )

    return texture
end

"""
    estimate_word_width(word::AbstractString, size_px::Int)::Float32

Estimate the width of a word based on character count and font size.
This is a fast approximation and is not pixel-perfect.
"""
function estimate_word_width(word::AbstractString, size_px::Int)::Float32
    # Simple estimate: assume average character width is about 0.6 * font_size
    # This works reasonably well for most fonts and is much faster
    avg_char_width = size_px * 0.6f0
    return Float32(length(word)) * avg_char_width
end

"""
    measure_word_width(font::FreeTypeAbstraction.FTFont, word::AbstractString, size_px::Int)::Float32

Measure the width of a word using FreeType for accurate rendering metrics.
This is more accurate but slower than estimate_word_width.
"""
function measure_word_width(font::FreeTypeAbstraction.FTFont, word::AbstractString, size_px::Int)::Float32
    width = 0.0f0
    for char in word
        _, extent = FreeTypeAbstraction.renderface(font, char, size_px)  # Avoid rendering
        width += Float32(extent.advance[1])
    end
    return width
end

function calculate_horizontal_offset(container_width::Real, text_width::Real, align::Symbol)::Float32
    if align == :left
        return 0.0f0
    elseif align == :center
        return (container_width - text_width) / 2.0f0
    elseif align == :right
        return container_width - text_width
    else
        error("Unsupported horizontal alignment: $align")
    end
end

function calculate_text_vertical_offset(container_height::Real, total_text_height::Real, line_height::Real, align::Symbol)::Float32
    if align == :top
        # For top alignment, start from the top (baseline of first line)
        return line_height
    elseif align == :middle
        # For middle alignment, center the entire text block in the container
        # The total_text_height represents the height of all lines combined
        # We want the center of the text block to be at the center of the container
        return (container_height - total_text_height) / 2.0f0 + line_height
    elseif align == :bottom
        # For bottom alignment, position so the last line is at the bottom
        return container_height - total_text_height + line_height
    else
        error("Unsupported vertical alignment: $align")
    end
end