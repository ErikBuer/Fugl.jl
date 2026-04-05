using GeometryBasics: MMatrix

function draw_text(
    font_face::FreeTypeAbstraction.FTFont,
    text::AbstractString,
    x::Float32,
    y::Float32,
    size_points::Int,
    projection_matrix::Mat4{Float32},
    color::Vec4{Float32};
    clip_bounds_points::Union{Rectangle,Nothing}=nothing
)
    # Convert effective coordinates to pixel coordinates for crisp text rendering
    dpi_scaling = get_current_dpi_scaling()
    system_dpi_ratio = get_system_dpi_ratio(dpi_scaling)
    manual_scale = dpi_scaling[].manual_scale

    # Scale coordinates by the same total factor used for glyph sizing
    # This ensures alignment calculations match the glyph coordinate system
    total_scale = manual_scale * system_dpi_ratio
    pixel_x = x * total_scale
    pixel_y = y * total_scale

    # Round to whole pixels for crisp rendering
    snapped_pixel_x = Float32(round(pixel_x))
    snapped_pixel_y = Float32(round(pixel_y))

    # Convert the passed projection matrix from points to pixels
    # Scale the projection matrix to work with pixel coordinates
    pixel_projection_matrix = MMatrix{4,4,Float32}(projection_matrix)
    pixel_projection_matrix[1, 1] /= total_scale  # Scale x component for pixel coordinates
    pixel_projection_matrix[2, 2] /= total_scale  # Scale y component for pixel coordinates
    pixel_projection_matrix = Mat4{Float32}(pixel_projection_matrix)  # Convert back to SMatrix

    # Convert clip bounds from points to pixels if provided
    clip_px = if isnothing(clip_bounds_points)
        nothing
    else
        cb = clip_bounds_points
        (Float32(round(cb.x * total_scale)),
            Float32(round(cb.y * total_scale)),
            Float32(round((cb.x + cb.width) * total_scale)),
            Float32(round((cb.y + cb.height) * total_scale)))
    end

    batch = get_global_text_batch()
    return draw_text_batched(font_face, text, snapped_pixel_x, snapped_pixel_y, size_points, pixel_projection_matrix, color, batch; clip_bounds_px=clip_px)
end


"""
    draw_glyph_from_atlas(texture, x, y, width, height, u_min, v_min, u_max, v_max, projection_matrix, color)

Draw a single glyph from the atlas texture with specified UV coordinates.
"""
function draw_glyph_from_atlas(
    atlas_texture::GLAbstraction.Texture,
    x::Float32, y::Float32,
    width::Float32, height::Float32,
    u_min::Float32, v_min::Float32, u_max::Float32, v_max::Float32,
    projection_matrix::Mat4{Float32},
    color::Vec4{Float32}
)
    # Define rectangle vertices
    positions = [
        Point2f(x, y + height),           # Top-left
        Point2f(x + width, y + height),   # Top-right
        Point2f(x + width, y),            # Bottom-right
        Point2f(x, y),                    # Bottom-left
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
    x::Float32, y::Float32,
    scale::Float32,
    projection_matrix::Mat4{Float32}
)
    atlas_width = Float32(atlas.width) * scale
    atlas_height = Float32(atlas.height) * scale

    # Define rectangle vertices for the full atlas
    positions = [
        Point2f(x, y + atlas_height),           # Top-left
        Point2f(x + atlas_width, y + atlas_height),   # Top-right
        Point2f(x + atlas_width, y),            # Bottom-right
        Point2f(x, y),                          # Bottom-left
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
    size_points::Int,
    projection_matrix::Mat4{Float32},
    color::Vec4{Float32},
    batch::GlyphBatch=GlyphBatch();
    clip_bounds_px::Union{NTuple{4,Float32},Nothing}=nothing
)
    # Convert from points to pixel coordinates for crisp rendering
    # Use both manual_scale and system_dpi_ratio for proper pixel sizing
    dpi_scaling = get_current_dpi_scaling()
    system_dpi_ratio = get_system_dpi_ratio(dpi_scaling)
    manual_scale = dpi_scaling[].manual_scale

    # Scale size by both manual scale and system DPI ratio for pixel-perfect rendering
    pixel_size = Int(round(Float32(size_points) * manual_scale * system_dpi_ratio))

    atlas = get_glyph_atlas()
    current_x = 0.0f0  # Start at 0, will be transformed relative to origin
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

        # Get glyph from atlas using pixel size for pixel coordinate rendering
        glyph_uv = get_or_insert_glyph!(atlas, font_face, char, pixel_size)

        # Add to batch if it has content
        if glyph_uv.width > 0 && glyph_uv.height > 0
            # Calculate glyph position
            glyph_x = x_px + current_x + glyph_uv.bearing_x
            glyph_y = y_px - glyph_uv.bearing_y  # Negative because glyph bearing_y is upward

            # Snap glyph positions to pixel boundaries for crisp rendering
            snapped_glyph_x = Float32(round(glyph_x))
            snapped_glyph_y = Float32(round(glyph_y))

            if isnothing(clip_bounds_px)
                add_glyph_to_batch!(
                    batch,
                    snapped_glyph_x, snapped_glyph_y,
                    Float32(glyph_uv.width), Float32(glyph_uv.height),
                    glyph_uv.u_min, glyph_uv.v_min, glyph_uv.u_max, glyph_uv.v_max
                )
            else
                clip_x_min, clip_y_min, clip_x_max, clip_y_max = clip_bounds_px
                vis_x_min = max(snapped_glyph_x, clip_x_min)
                vis_x_max = min(snapped_glyph_x + glyph_uv.width, clip_x_max)
                vis_y_min = max(snapped_glyph_y, clip_y_min)
                vis_y_max = min(snapped_glyph_y + glyph_uv.height, clip_y_max)

                if vis_x_min < vis_x_max && vis_y_min < vis_y_max
                    inv_w = 1.0f0 / Float32(glyph_uv.width)
                    inv_h = 1.0f0 / Float32(glyph_uv.height)
                    du = glyph_uv.u_max - glyph_uv.u_min
                    dv = glyph_uv.v_max - glyph_uv.v_min
                    u_vis_min = glyph_uv.u_min + (vis_x_min - snapped_glyph_x) * inv_w * du
                    u_vis_max = glyph_uv.u_min + (vis_x_max - snapped_glyph_x) * inv_w * du
                    v_vis_min = glyph_uv.v_min + (vis_y_min - snapped_glyph_y) * inv_h * dv
                    v_vis_max = glyph_uv.v_min + (vis_y_max - snapped_glyph_y) * inv_h * dv
                    add_glyph_to_batch!(
                        batch,
                        vis_x_min, vis_y_min,
                        vis_x_max - vis_x_min, vis_y_max - vis_y_min,
                        u_vis_min, v_vis_min, u_vis_max, v_vis_max
                    )
                end
            end
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

An optional `clip_bounds_points` tuple `(x, y, width, height)` (in points) can be
provided. Glyphs that overlap the boundary are clipped: both the quad geometry and
the atlas UV coordinates are trimmed proportionally, so partial characters are
rendered correctly rather than being fully omitted.
"""
function draw_multiline_text_batched(
    font_face::FreeTypeAbstraction.FTFont,
    lines::Vector{String},
    x_positions::Vector{Float32},
    y_positions::Vector{Float32},
    size_points::Int,
    projection_matrix_points::Mat4{Float32},
    color::Vec4{Float32},
    batch::GlyphBatch=GlyphBatch();
    clip_bounds_points::Union{Rectangle,Nothing}=nothing
)
    # Use pixel-based scaling for crisp rendering (matches draw_text_batched)
    dpi_scaling = get_current_dpi_scaling()
    system_dpi_ratio = get_system_dpi_ratio(dpi_scaling)
    manual_scale = dpi_scaling[].manual_scale
    # Scale size by both manual scale and system DPI ratio for pixel-perfect rendering
    pixel_size = Int(round(Float32(size_points) * manual_scale * system_dpi_ratio))

    # Convert position arrays from effective coordinates to pixel coordinates 
    # (matches draw_text coordinate conversion)
    total_scale = manual_scale * system_dpi_ratio
    pixel_x_positions = [Float32(round(x * total_scale)) for x in x_positions]
    pixel_y_positions = [Float32(round(y * total_scale)) for y in y_positions]

    # Pre-compute clip bounds in pixel space (if provided)
    clip_x_min_px = clip_x_max_px = clip_y_min_px = clip_y_max_px = 0.0f0
    has_clip = !isnothing(clip_bounds_points)
    if has_clip
        clip_x_min_px = Float32(round(clip_bounds_points.x * total_scale))
        clip_y_min_px = Float32(round(clip_bounds_points.y * total_scale))
        clip_x_max_px = Float32(round((clip_bounds_points.x + clip_bounds_points.width) * total_scale))
        clip_y_max_px = Float32(round((clip_bounds_points.y + clip_bounds_points.height) * total_scale))
    end

    # Convert the passed projection matrix from points to pixels
    # The projection matrix is already set up for the correct rendering target (window or framebuffer)
    # We just need to scale it to work with pixel coordinates instead of point coordinates
    pixel_projection_matrix = MMatrix{4,4,Float32}(projection_matrix_points)
    pixel_projection_matrix[1, 1] /= total_scale  # Scale x component for pixel coordinates
    pixel_projection_matrix[2, 2] /= total_scale  # Scale y component for pixel coordinates
    pixel_projection_matrix = Mat4{Float32}(pixel_projection_matrix)  # Convert back to SMatrix

    atlas = get_glyph_atlas()

    # Clear the batch for reuse
    clear_batch!(batch)

    # Process all lines and collect all glyphs into the batch
    for (line_idx, line) in enumerate(lines)
        if line_idx > length(pixel_x_positions) || line_idx > length(pixel_y_positions)
            break
        end

        line_origin_x = pixel_x_positions[line_idx]
        line_origin_y = pixel_y_positions[line_idx]
        current_x = 0.0f0  # Start at 0, will be transformed relative to line origin
        prev_char::Union{Char,Nothing} = nothing

        # Process each character in this line
        for char in line
            # Handle kerning
            if prev_char !== nothing
                kx, _ = map(x -> round(Int, x), FreeTypeAbstraction.kerning(prev_char, char, font_face))
                current_x += kx
            end

            # Get glyph from atlas using pixel size (matches other text functions)
            glyph_uv = get_or_insert_glyph!(atlas, font_face, char, pixel_size)

            # Calculate glyph position (always, so advance stays correct)
            glyph_x = line_origin_x + current_x + glyph_uv.bearing_x
            glyph_y = line_origin_y - glyph_uv.bearing_y  # Negative because glyph bearing_y is upward

            # Snap glyph positions to pixel boundaries for crisp rendering
            snapped_glyph_x = Float32(round(glyph_x))
            snapped_glyph_y = Float32(round(glyph_y))

            # Add to batch only if the glyph has renderable content
            if glyph_uv.width > 0 && glyph_uv.height > 0
                if !has_clip
                    # No clipping — add the full glyph quad
                    add_glyph_to_batch!(
                        batch,
                        snapped_glyph_x, snapped_glyph_y,
                        Float32(glyph_uv.width), Float32(glyph_uv.height),
                        glyph_uv.u_min, glyph_uv.v_min, glyph_uv.u_max, glyph_uv.v_max
                    )
                else
                    # Clip the glyph quad against the clip bounds.
                    # Compute the visible screen-space rectangle.
                    vis_x_min = max(snapped_glyph_x, clip_x_min_px)
                    vis_x_max = min(snapped_glyph_x + glyph_uv.width, clip_x_max_px)
                    vis_y_min = max(snapped_glyph_y, clip_y_min_px)
                    vis_y_max = min(snapped_glyph_y + glyph_uv.height, clip_y_max_px)

                    # Skip glyphs that are fully outside the clip region
                    if vis_x_min < vis_x_max && vis_y_min < vis_y_max
                        # Proportionally adjust UV coordinates to match the clipped geometry.
                        # u/v vary linearly across the glyph quad:
                        #   u = u_min + (x - x0) / w * (u_max - u_min)
                        #   v = v_min + (y - y0) / h * (v_max - v_min)
                        inv_w = 1.0f0 / Float32(glyph_uv.width)
                        inv_h = 1.0f0 / Float32(glyph_uv.height)
                        du = glyph_uv.u_max - glyph_uv.u_min
                        dv = glyph_uv.v_max - glyph_uv.v_min

                        u_vis_min = glyph_uv.u_min + (vis_x_min - snapped_glyph_x) * inv_w * du
                        u_vis_max = glyph_uv.u_min + (vis_x_max - snapped_glyph_x) * inv_w * du
                        v_vis_min = glyph_uv.v_min + (vis_y_min - snapped_glyph_y) * inv_h * dv
                        v_vis_max = glyph_uv.v_min + (vis_y_max - snapped_glyph_y) * inv_h * dv

                        add_glyph_to_batch!(
                            batch,
                            vis_x_min, vis_y_min,
                            vis_x_max - vis_x_min, vis_y_max - vis_y_min,
                            u_vis_min, v_vis_min, u_vis_max, v_vis_max
                        )
                    end
                end
            end

            # Advance position
            current_x += glyph_uv.advance
            prev_char = char
        end
    end

    # Render the entire batch with all lines using pixel coordinate system
    render_glyph_batch!(batch, atlas.texture, pixel_projection_matrix, color)

    return batch
end


