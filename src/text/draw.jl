function draw_text(
    font_face::FreeTypeAbstraction.FTFont,
    text::AbstractString,
    x_px::Float32,
    y_px::Float32,
    pixelsize::Int,
    projection_matrix::Mat4{Float32},
    color::Vec4{Float32}
)
    # Use glyph atlas exclusively for fast text rendering
    atlas = get_glyph_atlas()
    current_x = x_px
    prev_char::Union{Char,Nothing} = nothing

    for char in text
        # Handle kerning
        if prev_char !== nothing
            kx, _ = map(x -> round(Int, x), FreeTypeAbstraction.kerning(prev_char, char, font_face))
            current_x += kx
        end

        # Get glyph from atlas (this will cache it if not present)
        glyph_uv = get_or_insert_glyph!(atlas, font_face, char, pixelsize)


        # Render the glyph if it has content
        if glyph_uv.width > 0 && glyph_uv.height > 0
            # Calculate glyph position
            glyph_x = current_x + glyph_uv.bearing_x
            glyph_y = y_px - glyph_uv.bearing_y


            # Render from atlas
            draw_glyph_from_atlas(
                atlas.texture,
                glyph_x, glyph_y,
                Float32(glyph_uv.width), Float32(glyph_uv.height),
                glyph_uv.u_min, glyph_uv.v_min, glyph_uv.u_max, glyph_uv.v_max,
                projection_matrix, color
            )
        end

        # Advance position
        current_x += glyph_uv.advance
        prev_char = char
    end
end


function draw_glyph(texture::GLAbstraction.Texture, x_px::AbstractFloat, y_px::AbstractFloat, projection_matrix::Mat4{Float32}; scale::AbstractFloat=1.0, color::Vec4{Float32}=Vec{4,Float32}(1.0, 1.0, 1.0, 1.0))
    # Get the image size from the texture
    width_px, height_px = Float32.(GLA.size(texture))

    scaled_width_px = width_px * scale
    scaled_height_px = height_px * scale

    # Define rectangle vertices
    positions = [
        Point2f(x_px, y_px + scaled_height_px),                   # Top-left
        Point2f(x_px + scaled_width_px, y_px + scaled_height_px), # Top-right
        Point2f(x_px + scaled_width_px, y_px),                    # Bottom-right
        Point2f(x_px, y_px),                                      # Bottom-left
    ]

    # Define texture coordinates (corrected for OpenGL's coordinate system)
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

    # Set the `use_texture` uniform to true
    GLA.gluniform(glyph_prog[], :use_texture, true)
    GLA.gluniform(glyph_prog[], :image, 0, texture)
    GLA.gluniform(glyph_prog[], :projection, projection_matrix)
    GLA.gluniform(glyph_prog[], :text_color, color)

    # Bind the VAO and draw the rectangle
    GLA.bind(vao)
    GLA.draw(vao)

    # Unbind the VAO and shader program
    GLA.unbind(vao)
    GLA.unbind(glyph_prog[])
end

"""
    draw_glyphs_batched(texture, glyph_data, projection_matrix, color)

Draw multiple glyphs from the atlas texture in a single batch.
This is much more efficient than individual glyph rendering.
"""
function draw_glyphs_batched(
    atlas_texture::GLAbstraction.Texture,
    glyph_data::Vector,
    projection_matrix::Mat4{Float32},
    color::Vec4{Float32}
)
    # TODO: In a full implementation, you'd want to batch all glyphs into
    # a single draw call with instanced rendering or a vertex buffer.
    # For now, we'll use individual quads but with the shared atlas texture

    for (glyph_x, glyph_y, width, height, u_min, v_min, u_max, v_max) in glyph_data
        draw_glyph_from_atlas(
            atlas_texture,
            glyph_x, glyph_y, width, height,
            u_min, v_min, u_max, v_max,
            projection_matrix, color
        )
    end
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