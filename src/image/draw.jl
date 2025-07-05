function draw_image(texture::GLAbstraction.Texture, x_px::AbstractFloat, y_px::AbstractFloat, projection_matrix::Mat4{Float32}; scale::AbstractFloat=1.0)

    # Get the image size from the texture
    width_px, height_px = Float32.(GLA.size(texture))


    scaled_width_px = width_px * scale
    scaled_height_px = height_px * scale

    # Define rectangle vertices
    positions = [
        Point2f(x_px, y_px + scaled_height_px),                   # Bottom-left
        Point2f(x_px + scaled_width_px, y_px + scaled_height_px), # Bottom-right
        Point2f(x_px + scaled_width_px, y_px),                    # Top-right
        Point2f(x_px, y_px),                                      # Top-left
    ]

    # Define texture coordinates
    texturecoordinates = [
        Vec{2,Float32}(1, 0),  # Bottom-right
        Vec{2,Float32}(1, 1),  # Top-right
        Vec{2,Float32}(0, 1),  # Top-left    
        Vec{2,Float32}(0, 0),  # Bottom-left
    ]

    # Define the elements (two triangles forming the rectangle)
    indices = NgonFace{3,UInt32}[
        (0, 1, 2),  # First triangle: bottom-left, bottom-right, top-right
        (2, 3, 0)   # Second triangle: top-right, top-left, bottom-left
    ]

    # Generate buffers and create a Vertex Array Object (VAO)
    vao = GLA.VertexArray(
        GLA.generate_buffers(
            prog[],
            position=positions,
            texcoord=texturecoordinates
        ),
        indices
    )

    # Bind the shader program
    GLA.bind(prog[])

    # Set the `use_texture` uniform to true
    GLA.gluniform(prog[], :use_texture, true)

    # Bind the texture to the shader's sampler2D uniform
    GLA.gluniform(prog[], :image, 0, texture)

    GLA.gluniform(prog[], :projection, projection_matrix)

    # Bind the VAO and draw the rectangle
    GLA.bind(vao)
    GLA.draw(vao)

    # Unbind the VAO and shader program
    GLA.unbind(vao)
    GLA.unbind(prog[])
end