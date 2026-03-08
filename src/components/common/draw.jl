"""
    draw_closed_lines(vertices::Vector{Point2f}, color_rgba::Vec4{<:Float32})

Draw closed lines using the provided vertices and color.
"""
function draw_closed_lines(vertices::Vector{Point2f}, color_rgba::Vec4{<:Float32})
    # Generate a uniform color array for all vertices
    colors = Vec{4,Float32}[color_rgba for _ in 1:length(vertices)]

    # Generate buffers for positions and colors
    buffers = GLA.generate_buffers(prog[], position=vertices, color=colors)

    # Create a Vertex Array Object (VAO) with the primitive type GL_LINE_LOOP
    vao = GLA.VertexArray(buffers, GL_LINE_LOOP)

    # Bind the shader program and VAO
    GLA.bind(prog[])
    GLA.bind(vao)

    # Draw the vertices using the VAO
    GLA.draw(vao)

    # Unbind the VAO and shader program
    GLA.unbind(vao)
    GLA.unbind(prog[])
end

"""
    draw_rectangle(vertices::Vector{Point2f}, color_rgba::Vec4{<:Float32}, projection_matrix::Mat4{Float32})

Draw a rectangle using the provided vertices and color.
"""
function draw_rectangle(vertices::Vector{Point2f}, color_rgba::Vec4{<:Float32}, projection_matrix::Mat4{Float32})
    # Generate a uniform color array for all vertices
    colors = Vec{4,Float32}[color_rgba for _ in 1:4]

    # Define the elements (two triangles forming the rectangle)
    elements = NgonFace{3,UInt32}[
        (0, 1, 2),  # First triangle: bottom-left, bottom-right, top-right
        (2, 3, 0)   # Second triangle: top-right, top-left, bottom-left
    ]

    # Generate buffers for positions and colors
    buffers = GLA.generate_buffers(prog[], position=vertices, color=colors)

    # Create a Vertex Array Object (VAO) with the primitive type GL_TRIANGLES
    vao = GLA.VertexArray(buffers, elements)

    # Bind the shader program and VAO
    GLA.bind(prog[])
    GLA.bind(vao)

    # Ensure the shader's `use_texture` uniform is set to `false`
    GLA.gluniform(prog[], :use_texture, false)
    GLA.gluniform(prog[], :projection, projection_matrix)

    # Draw the rectangle using the VAO
    GLA.draw(vao)

    # Unbind the VAO and shader program
    GLA.unbind(vao)
    GLA.unbind(prog[])
end

"""
    draw_rounded_rectangle(
        vertices::Vector{Point2f},
        width::Float32, height::Float32,
        fill_color_rgba::Vec4{<:Float32}, border_color_rgba::Vec4{<:Float32},
        border_width::Float32, radius::Float32,
        projection_matrix::Mat4{Float32},
        anti_aliasing_width::Float32
    )

Draw a rounded rectangle with border using the custom shader.
"""
function draw_rounded_rectangle(
    vertices::Vector{Point2f},
    width::Float32,
    height::Float32,
    fill_color_rgba::Vec4{<:Float32},
    border_color_rgba::Vec4{<:Float32},
    border_width::Float32,
    radius::Float32,
    projection_matrix::Mat4{Float32},
    anti_aliasing_width::Float32
)

    fill_color_f32 = Vec{4,Float32}(fill_color_rgba)
    border_color_f32 = Vec{4,Float32}(border_color_rgba)

    # UVs for [0,1] box, matching vertex order
    uvs = [
        Vec{2,Float32}(0, 1),  # Top-left    
        Vec{2,Float32}(0, 0),  # Bottom-left
        Vec{2,Float32}(1, 0),  # Bottom-right
        Vec{2,Float32}(1, 1),  # Top-right
    ]
    elements = NgonFace{3,UInt32}[
        (0, 1, 2),
        (2, 3, 0)
    ]


    buffers = GLA.generate_buffers(rounded_rect_prog[], position=vertices, uv=uvs)
    vao = GLA.VertexArray(buffers, elements)

    GLA.bind(rounded_rect_prog[])
    GLA.bind(vao)

    GLA.gluniform(rounded_rect_prog[], :projection, projection_matrix)
    GLA.gluniform(rounded_rect_prog[], :fill_color, fill_color_f32)
    GLA.gluniform(rounded_rect_prog[], :border_color, border_color_f32)
    GLA.gluniform(rounded_rect_prog[], :border_width, border_width)
    GLA.gluniform(rounded_rect_prog[], :radius, radius)
    GLA.gluniform(rounded_rect_prog[], :aa, anti_aliasing_width)
    GLA.gluniform(rounded_rect_prog[], :rect_size, Vec{2,Float32}(width, height))

    GLA.draw(vao)

    GLA.unbind(vao)
    GLA.unbind(rounded_rect_prog[])
end

"""
    draw_configurable_rectangle(
        vertices, width, height, fill_color, border_color, border_width,
        corner_radii, projection_matrix, anti_aliasing_width
    )

Draw a rectangle with configurable per-corner radii.

# Arguments
- `vertices`: Vector of corner positions
- `width`, `height`: Rectangle dimensions
- `fill_color`: Fill color as Vec4
- `border_color`: Border color as Vec4  
- `border_width`: Border thickness in pixels
- `corner_radii`: Vec4 of corner radii (top-left, top-right, bottom-right, bottom-left)
- `projection_matrix`: Projection matrix
- `anti_aliasing_width`: Anti-aliasing width in pixels
"""
function draw_configurable_rectangle(
    vertices::Vector{Point2f},
    width::Float32,
    height::Float32,
    fill_color_rgba::Vec4{<:Float32},
    border_color_rgba::Vec4{<:Float32},
    border_width::Float32,
    corner_radii::Vec4{<:Float32},
    projection_matrix::Mat4{Float32},
    anti_aliasing_width::Float32
)

    fill_color_f32 = Vec{4,Float32}(fill_color_rgba)
    border_color_f32 = Vec{4,Float32}(border_color_rgba)

    # UVs for [0,1] box, matching vertex order
    uvs = [
        Vec{2,Float32}(0, 1),  # Top-left    
        Vec{2,Float32}(0, 0),  # Bottom-left
        Vec{2,Float32}(1, 0),  # Bottom-right
        Vec{2,Float32}(1, 1),  # Top-right
    ]
    elements = NgonFace{3,UInt32}[
        (0, 1, 2),
        (2, 3, 0)
    ]

    buffers = GLA.generate_buffers(configurable_rect_prog[], position=vertices, uv=uvs)
    vao = GLA.VertexArray(buffers, elements)

    GLA.bind(configurable_rect_prog[])
    GLA.bind(vao)

    GLA.gluniform(configurable_rect_prog[], :projection, projection_matrix)
    GLA.gluniform(configurable_rect_prog[], :fill_color, fill_color_f32)
    GLA.gluniform(configurable_rect_prog[], :border_color, border_color_f32)
    GLA.gluniform(configurable_rect_prog[], :border_width, border_width)
    GLA.gluniform(configurable_rect_prog[], :corner_radii, corner_radii)
    GLA.gluniform(configurable_rect_prog[], :aa, anti_aliasing_width)
    GLA.gluniform(configurable_rect_prog[], :rect_size, Vec{2,Float32}(width, height))

    GLA.draw(vao)

    GLA.unbind(vao)
    GLA.unbind(configurable_rect_prog[])
end