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

function calculate_text_vertical_offset(container_height::Real, text_height::Real, align::Symbol)::Float32
    if align == :top
        return 0.0f0 + text_height
    elseif align == :middle
        return (container_height + text_height) / 2.0f0
    elseif align == :bottom
        return container_height - text_height / 2.0f0
    else
        error("Unsupported vertical alignment: $align")
    end
end