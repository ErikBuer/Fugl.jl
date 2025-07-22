# Backup of draw.jl with original per-glyph rendering
# This can be used to test if the issue is in the atlas or elsewhere

function draw_text_original(
    font_face::FreeTypeAbstraction.FTFont,
    text::AbstractString,
    x_px::Float32,
    y_px::Float32,
    pixelsize::Int,
    projection_matrix::Mat4{Float32},
    color::Vec4{Float32}
)
    current_x = x_px
    prev_char::Union{Char,Nothing} = nothing

    for char in text
        # Handle kerning
        if prev_char !== nothing
            kx, _ = map(x -> round(Int, x), FreeTypeAbstraction.kerning(prev_char, char, font_face))
            current_x += kx
        end

        # Render the glyph to bitmap
        bitmap, extent = FreeTypeAbstraction.renderface(font_face, char, pixelsize)

        # Skip empty glyphs but still advance
        if isempty(bitmap) || size(bitmap, 1) == 0 || size(bitmap, 2) == 0
            current_x += Float32(extent.advance[1])
            prev_char = char
            continue
        end

        # Convert bitmap to texture
        mat = Float32.(bitmap) ./ 255.0f0
        texture = create_text_texture(mat)

        # Calculate glyph position
        glyph_x = current_x + Float32(extent.horizontal_bearing[1])
        glyph_y = y_px - Float32(extent.horizontal_bearing[2])

        # Render the glyph
        draw_glyph(texture, glyph_x, glyph_y, projection_matrix; color=color)

        # Advance position
        current_x += Float32(extent.advance[1])
        prev_char = char
    end
end
