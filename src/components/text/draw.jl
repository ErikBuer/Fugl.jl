function draw_text(
    font_face::FreeTypeAbstraction.FTFont,
    text::AbstractString,
    x_px::Float32,
    y_px::Float32,
    pixelsize::Int,
    projection_matrix::Mat4{Float32},
    color::Vec4{Float32}
)
    batch = get_global_text_batch()
    return draw_text_batched(font_face, text, x_px, y_px, pixelsize, projection_matrix, color, batch)
end


"""
    draw_glyph_from_atlas(texture, x, y, width, height, u_min, v_min, u_max, v_max, projection_matrix, color)

Draw a single glyph from the atlas texture with specified UV coordinates.
"""
function draw_glyph_from_atlas(
    atlas_texture::GLAbstraction.Texture,
    x_px::Float32, y_px::Float32,
    width::Float32, height::Float32,
    u_min::Float32, v_min::Float32, u_max::Float32, v_max::Float32,
    projection_matrix::Mat4{Float32},
    color::Vec4{Float32}
)
    # Define rectangle vertices
    positions = [
        Point2f(x_px, y_px + height),           # Top-left
        Point2f(x_px + width, y_px + height),   # Top-right
        Point2f(x_px + width, y_px),            # Bottom-right
        Point2f(x_px, y_px),                    # Bottom-left
    ]

    # Define texture coordinates from atlas UV
    texturecoordinates = [
        Vec{2,Float32}(u_min, v_max),  # Top-left
        Vec{2,Float32}(u_max, v_max),  # Top-right
        Vec{2,Float32}(u_max, v_min),  # Bottom-right
        Vec{2,Float32}(u_min, v_min),  # Bottom-left
    ]

    # Define the elements (two triangles forming the rectangle)
    indices = NgonFace{3,UInt32}[
        (0, 1, 2),  # First triangle
        (2, 3, 0)   # Second triangle
    ]

    # Generate buffers and create a Vertex Array Object (VAO)
    vao = GLA.VertexArray(
        GLA.generate_buffers(
            glyph_prog[],
            position=positions,
            texcoord=texturecoordinates
        ),
        indices
    )

    # Bind the shader program
    GLA.bind(glyph_prog[])

    # Set uniforms
    GLA.gluniform(glyph_prog[], :use_texture, true)
    GLA.gluniform(glyph_prog[], :image, 0, atlas_texture)  # Use atlas texture
    GLA.gluniform(glyph_prog[], :projection, projection_matrix)
    GLA.gluniform(glyph_prog[], :text_color, color)

    # Bind the VAO and draw
    GLA.bind(vao)
    GLA.draw(vao)

    # Unbind
    GLA.unbind(vao)
    GLA.unbind(glyph_prog[])
end

"""
    draw_glyph_atlas_debug(atlas, x, y, scale, projection_matrix)

Draw the entire glyph atlas texture to the screen for debugging purposes.
This helps visualize what glyphs are actually stored in the atlas.
"""
function draw_glyph_atlas_debug(
    atlas::GlyphAtlas,
    x_px::Float32, y_px::Float32,
    scale::Float32,
    projection_matrix::Mat4{Float32}
)
    atlas_width = Float32(atlas.width) * scale
    atlas_height = Float32(atlas.height) * scale

    # Define rectangle vertices for the full atlas
    positions = [
        Point2f(x_px, y_px + atlas_height),           # Top-left
        Point2f(x_px + atlas_width, y_px + atlas_height),   # Top-right
        Point2f(x_px + atlas_width, y_px),            # Bottom-right
        Point2f(x_px, y_px),                          # Bottom-left
    ]

    # Define texture coordinates to show the entire atlas
    texturecoordinates = [
        Vec{2,Float32}(0.0f0, 1.0f0),  # Top-left
        Vec{2,Float32}(1.0f0, 1.0f0),  # Top-right
        Vec{2,Float32}(1.0f0, 0.0f0),  # Bottom-right
        Vec{2,Float32}(0.0f0, 0.0f0),  # Bottom-left
    ]

    # Define the elements (two triangles forming the rectangle)
    indices = NgonFace{3,UInt32}[
        (0, 1, 2),  # First triangle
        (2, 3, 0)   # Second triangle
    ]

    # Generate buffers and create a Vertex Array Object (VAO)
    vao = GLA.VertexArray(
        GLA.generate_buffers(
            glyph_prog[],
            position=positions,
            texcoord=texturecoordinates
        ),
        indices
    )

    # Bind the shader program
    GLA.bind(glyph_prog[])

    # Set uniforms
    GLA.gluniform(glyph_prog[], :use_texture, true)
    GLA.gluniform(glyph_prog[], :image, 0, atlas.texture)
    GLA.gluniform(glyph_prog[], :projection, projection_matrix)
    GLA.gluniform(glyph_prog[], :text_color, Vec4f(1.0, 1.0, 1.0, 1.0))  # White color

    # Bind the VAO and draw
    GLA.bind(vao)
    GLA.draw(vao)

    # Unbind
    GLA.unbind(vao)
    GLA.unbind(glyph_prog[])
end



"""
Render all glyphs in the batch with a single draw call.
This is dramatically faster than individual glyph rendering.
"""
function render_glyph_batch!(
    batch::GlyphBatch,
    atlas_texture::GLAbstraction.Texture,
    projection_matrix::Mat4{Float32},
    color::Vec4{Float32}
)
    if isempty(batch.positions)
        return  # Nothing to render
    end

    # Convert indices to the correct format
    triangle_indices = NgonFace{3,UInt32}[]
    for i in 1:3:length(batch.indices)
        if i + 2 <= length(batch.indices)
            push!(triangle_indices, NgonFace{3,UInt32}(
                batch.indices[i], batch.indices[i+1], batch.indices[i+2]
            ))
        end
    end

    # Create VAO with all batch data
    vao = GLA.VertexArray(
        GLA.generate_buffers(
            glyph_prog[],
            position=batch.positions,
            texcoord=batch.texture_coords
        ),
        triangle_indices
    )

    # Bind shader and set uniforms
    GLA.bind(glyph_prog[])
    GLA.gluniform(glyph_prog[], :use_texture, true)
    GLA.gluniform(glyph_prog[], :image, 0, atlas_texture)
    GLA.gluniform(glyph_prog[], :projection, projection_matrix)
    GLA.gluniform(glyph_prog[], :text_color, color)

    # Draw everything in one call
    GLA.bind(vao)
    GLA.draw(vao)

    # Cleanup
    GLA.unbind(vao)
    GLA.unbind(glyph_prog[])
end

"""
Optimized batched text rendering function that collects all glyphs first,
then renders them in a single draw call. Much faster for large amounts of text.
"""
function draw_text_batched(
    font_face::FreeTypeAbstraction.FTFont,
    text::AbstractString,
    x_px::Float32,
    y_px::Float32,
    pixelsize::Int,
    projection_matrix::Mat4{Float32},
    color::Vec4{Float32},
    batch::GlyphBatch=GlyphBatch()
)
    atlas = get_glyph_atlas()
    current_x = x_px
    prev_char::Union{Char,Nothing} = nothing

    # Clear the batch for reuse
    clear_batch!(batch)

    # Collect all glyphs in the batch
    for char in text
        # Handle kerning
        if prev_char !== nothing
            kx, _ = map(x -> round(Int, x), FreeTypeAbstraction.kerning(prev_char, char, font_face))
            current_x += kx
        end

        # Get glyph from atlas
        glyph_uv = get_or_insert_glyph!(atlas, font_face, char, pixelsize)

        # Add to batch if it has content
        if glyph_uv.width > 0 && glyph_uv.height > 0
            glyph_x = current_x + glyph_uv.bearing_x
            glyph_y = y_px - glyph_uv.bearing_y

            add_glyph_to_batch!(
                batch,
                glyph_x, glyph_y,
                Float32(glyph_uv.width), Float32(glyph_uv.height),
                glyph_uv.u_min, glyph_uv.v_min, glyph_uv.u_max, glyph_uv.v_max
            )
        end

        # Advance position
        current_x += glyph_uv.advance
        prev_char = char
    end

    # Render the entire batch
    render_glyph_batch!(batch, atlas.texture, projection_matrix, color)

    return batch  # Return for potential reuse
end

"""
Multi-line batched text rendering that collects all lines into a single batch.
This provides maximum performance for rendering multiple lines of text.
"""
function draw_multiline_text_batched(
    font_face::FreeTypeAbstraction.FTFont,
    lines::Vector{String},
    x_positions::Vector{Float32},
    y_positions::Vector{Float32},
    pixelsize::Int,
    projection_matrix::Mat4{Float32},
    color::Vec4{Float32},
    batch::GlyphBatch=GlyphBatch()
)
    atlas = get_glyph_atlas()

    # Clear the batch for reuse
    clear_batch!(batch)

    # Process all lines and collect all glyphs into the batch
    for (line_idx, line) in enumerate(lines)
        if line_idx > length(x_positions) || line_idx > length(y_positions)
            break
        end

        current_x = x_positions[line_idx]
        current_y = y_positions[line_idx]
        prev_char::Union{Char,Nothing} = nothing

        # Process each character in this line
        for char in line
            # Handle kerning
            if prev_char !== nothing
                kx, _ = map(x -> round(Int, x), FreeTypeAbstraction.kerning(prev_char, char, font_face))
                current_x += kx
            end

            # Get glyph from atlas
            glyph_uv = get_or_insert_glyph!(atlas, font_face, char, pixelsize)

            # Add to batch if it has content
            if glyph_uv.width > 0 && glyph_uv.height > 0
                glyph_x = current_x + glyph_uv.bearing_x
                glyph_y = current_y - glyph_uv.bearing_y

                add_glyph_to_batch!(
                    batch,
                    glyph_x, glyph_y,
                    Float32(glyph_uv.width), Float32(glyph_uv.height),
                    glyph_uv.u_min, glyph_uv.v_min, glyph_uv.u_max, glyph_uv.v_max
                )
            end

            # Advance position
            current_x += glyph_uv.advance
            prev_char = char
        end
    end

    # Render the entire batch with all lines
    render_glyph_batch!(batch, atlas.texture, projection_matrix, color)

    return batch
end


