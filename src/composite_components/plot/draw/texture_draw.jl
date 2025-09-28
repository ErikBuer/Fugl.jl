"""
Generalized texture-based rendering function for colormapped data.
Can be used by heatmaps, colorbars, and other texture-based visualizations.
"""
function draw_matrix_with_colormap(
    data::Matrix{Float32},
    colormap::Symbol,
    value_range::Tuple{Float32,Float32},
    nan_color::Tuple{Float32,Float32,Float32,Float32},
    background_color::Tuple{Float32,Float32,Float32,Float32},
    bottom_left_x::Float32, bottom_left_y::Float32,
    bottom_right_x::Float32, bottom_right_y::Float32,
    top_left_x::Float32, top_left_y::Float32,
    top_right_x::Float32, top_right_y::Float32,
    tex_x_min::Float32, tex_y_min::Float32,
    tex_x_max::Float32, tex_y_max::Float32,
    projection_matrix::Mat4{Float32}
)
    try
        # Apply colormap to create texture matrix
        matrix_data = apply_colormap_to_matrix(data, colormap)

        # Create texture from matrix
        texture = create_texture_from_matrix(matrix_data)

        # Create quad vertices 
        positions = [
            Point2f(bottom_left_x, bottom_left_y),     # Bottom-left
            Point2f(bottom_right_x, bottom_right_y),   # Bottom-right
            Point2f(top_right_x, top_right_y),         # Top-right
            Point2f(top_left_x, top_left_y),           # Top-left
        ]

        # Texture coordinates for the quad (using custom coordinates for clipping)
        texcoords = [
            Vec{2,Float32}(tex_x_min, tex_y_min),  # Bottom-left
            Vec{2,Float32}(tex_x_max, tex_y_min),  # Bottom-right
            Vec{2,Float32}(tex_x_max, tex_y_max),  # Top-right
            Vec{2,Float32}(tex_x_min, tex_y_max),  # Top-left
        ]

        # Add color attribute (white for texture rendering)
        colors = [
            Vec4f(1.0f0, 1.0f0, 1.0f0, 1.0f0),  # White
            Vec4f(1.0f0, 1.0f0, 1.0f0, 1.0f0),  # White
            Vec4f(1.0f0, 1.0f0, 1.0f0, 1.0f0),  # White
            Vec4f(1.0f0, 1.0f0, 1.0f0, 1.0f0),  # White
        ]

        # Define the elements (two triangles forming the rectangle)
        indices = NgonFace{3,UInt32}[
            (0, 1, 2),  # First triangle: bottom-left, bottom-right, top-right
            (2, 3, 0)   # Second triangle: top-right, top-left, bottom-left
        ]

        # Generate buffers and create a Vertex Array Object (VAO)
        vao = GLA.VertexArray(
            GLA.generate_buffers(
                plot_image_prog[],  # Use extended heatmap shader
                position=positions,
                color=colors,
                texcoord=texcoords
            ),
            indices
        )

        # Use the extended heatmap shader
        GLA.bind(plot_image_prog[])

        # Set all uniforms including extended ones
        GLA.gluniform(plot_image_prog[], :use_texture, true)
        GLA.gluniform(plot_image_prog[], :image, 0, texture)
        GLA.gluniform(plot_image_prog[], :projection, projection_matrix)
        GLA.gluniform(plot_image_prog[], :value_range, Vec2f(value_range))
        GLA.gluniform(plot_image_prog[], :nan_color, Vec4f(nan_color))
        GLA.gluniform(plot_image_prog[], :background_color, Vec4f(background_color))
        GLA.gluniform(plot_image_prog[], :colormap_type, colormap_to_int(colormap))

        # Draw the quad
        GLA.bind(vao)
        GLA.draw(vao)
        GLA.unbind(vao)
        GLA.unbind(plot_image_prog[])

    catch e
        @warn "Failed to draw textured quad: $e"
    end
end