struct ImagePlotElement <: AbstractPlotElement
    data::Matrix{Float32}
    x_range::Tuple{Float32,Float32}  # (min_x, max_x)
    y_range::Tuple{Float32,Float32}  # (min_y, max_y)
    colormap::Symbol  # :viridis, :plasma, :grayscale, etc.
    label::String
end

function ImagePlotElement(
    data::Matrix{<:Real};
    x_range::Tuple{Real,Real}=(1, size(data, 2)),
    y_range::Tuple{Real,Real}=(1, size(data, 1)),
    colormap::Symbol=:viridis,
    label::String=""
)
    data_f32 = Float32.(data)
    x_range_f32 = (Float32(x_range[1]), Float32(x_range[2]))
    y_range_f32 = (Float32(y_range[1]), Float32(y_range[2]))
    return ImagePlotElement(data_f32, x_range_f32, y_range_f32, colormap, label)
end

# Colormap definitions - simple linear interpolation for now
function apply_colormap(value::Float32, colormap::Symbol)::Tuple{Float32,Float32,Float32,Float32}
    # Clamp value to [0, 1] range
    t = clamp(value, 0.0f0, 1.0f0)

    if colormap == :viridis
        # Viridis colormap approximation
        r = t * t * (3.0f0 - 2.0f0 * t) * 0.267f0 + (1.0f0 - t) * 0.267f0
        g = t * 0.874f0 + (1.0f0 - t) * 0.004f0
        b = t * 0.562f0 + (1.0f0 - t) * 0.329f0
        return (r, g, b, 1.0f0)
    elseif colormap == :plasma
        # Plasma colormap approximation
        r = t * 0.940f0 + (1.0f0 - t) * 0.050f0
        g = t * t * 0.796f0 + (1.0f0 - t) * 0.029f0
        b = t * 0.280f0 + (1.0f0 - t) * 0.527f0
        return (r, g, b, 1.0f0)
    elseif colormap == :grayscale
        # Grayscale
        return (t, t, t, 1.0f0)
    elseif colormap == :hot
        # Hot colormap (black -> red -> yellow -> white)
        if t < 0.33f0
            s = t / 0.33f0
            return (s, 0.0f0, 0.0f0, 1.0f0)
        elseif t < 0.66f0
            s = (t - 0.33f0) / 0.33f0
            return (1.0f0, s, 0.0f0, 1.0f0)
        else
            s = (t - 0.66f0) / 0.34f0
            return (1.0f0, 1.0f0, s, 1.0f0)
        end
    else
        # Default to grayscale for unknown colormaps
        return (t, t, t, 1.0f0)
    end
end

# Draw image plot using texture and existing shader - much more efficient!
function draw_image_plot(
    element::ImagePlotElement,
    data_to_screen::Function,
    projection_matrix::Mat4{Float32};
    anti_aliasing_width::Float32=1.5f0
)
    # Get screen coordinates for corners
    x_min, x_max = element.x_range
    y_min, y_max = element.y_range

    # Transform corner points to screen coordinates
    bottom_left_x, bottom_left_y = data_to_screen(x_min, y_min)
    bottom_right_x, bottom_right_y = data_to_screen(x_max, y_min)
    top_left_x, top_left_y = data_to_screen(x_min, y_max)
    top_right_x, top_right_y = data_to_screen(x_max, y_max)

    # Use texture-based rendering for all cases
    draw_image_plot_textured(element,
        bottom_left_x, bottom_left_y,
        bottom_right_x, bottom_right_y,
        top_left_x, top_left_y,
        top_right_x, top_right_y,
        projection_matrix)
end

# Draw image plot with clipping to effective bounds (plot axes)
function draw_image_plot_clipped(
    element::ImagePlotElement,
    data_to_screen::Function,
    projection_matrix::Mat4{Float32},
    effective_bounds::Rect2f;
    anti_aliasing_width::Float32=1.5f0
)
    # Image data bounds
    x_min, x_max = element.x_range
    y_min, y_max = element.y_range

    # Clip image bounds to effective plot bounds
    clipped_x_min = max(x_min, effective_bounds.x)
    clipped_x_max = min(x_max, effective_bounds.x + effective_bounds.width)
    clipped_y_min = max(y_min, effective_bounds.y)
    clipped_y_max = min(y_max, effective_bounds.y + effective_bounds.height)

    # If completely clipped, nothing to draw
    if clipped_x_min >= clipped_x_max || clipped_y_min >= clipped_y_max
        return
    end

    # Calculate texture coordinates for the clipped region
    # Normalize to [0,1] based on original image bounds
    tex_x_min = (clipped_x_min - x_min) / (x_max - x_min)
    tex_x_max = (clipped_x_max - x_min) / (x_max - x_min)
    tex_y_min = (clipped_y_min - y_min) / (y_max - y_min)
    tex_y_max = (clipped_y_max - y_min) / (y_max - y_min)

    # Transform clipped corner points to screen coordinates
    bottom_left_x, bottom_left_y = data_to_screen(clipped_x_min, clipped_y_min)
    bottom_right_x, bottom_right_y = data_to_screen(clipped_x_max, clipped_y_min)
    top_left_x, top_left_y = data_to_screen(clipped_x_min, clipped_y_max)
    top_right_x, top_right_y = data_to_screen(clipped_x_max, clipped_y_max)

    # Use texture-based rendering with custom texture coordinates
    draw_image_plot_textured_clipped(element,
        bottom_left_x, bottom_left_y,
        bottom_right_x, bottom_right_y,
        top_left_x, top_left_y,
        top_right_x, top_right_y,
        tex_x_min, tex_y_min,
        tex_x_max, tex_y_max,
        projection_matrix)
end

# Texture-based rendering using existing shader with precomputed colormap texture
function draw_image_plot_textured(
    element::ImagePlotElement,
    bottom_left_x::Float32, bottom_left_y::Float32,
    bottom_right_x::Float32, bottom_right_y::Float32,
    top_left_x::Float32, top_left_y::Float32,
    top_right_x::Float32, top_right_y::Float32,
    projection_matrix::Mat4{Float32}
)
    # Use full texture coordinates (0,0) to (1,1)
    draw_image_plot_textured_clipped(element,
        bottom_left_x, bottom_left_y,
        bottom_right_x, bottom_right_y,
        top_left_x, top_left_y,
        top_right_x, top_right_y,
        0.0f0, 0.0f0,  # tex_x_min, tex_y_min
        1.0f0, 1.0f0,  # tex_x_max, tex_y_max
        projection_matrix)
end

# Texture-based rendering with custom texture coordinates for clipping
function draw_image_plot_textured_clipped(
    element::ImagePlotElement,
    bottom_left_x::Float32, bottom_left_y::Float32,
    bottom_right_x::Float32, bottom_right_y::Float32,
    top_left_x::Float32, top_left_y::Float32,
    top_right_x::Float32, top_right_y::Float32,
    tex_x_min::Float32, tex_y_min::Float32,
    tex_x_max::Float32, tex_y_max::Float32,
    projection_matrix::Mat4{Float32}
)
    try
        # Apply colormap to create RGB matrix following image component pattern
        rgb_matrix = apply_colormap_to_matrix(element.data, element.colormap)

        # Create texture from RGB matrix
        texture = create_texture_from_matrix(rgb_matrix)

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

        # Define the elements (two triangles forming the rectangle)
        indices = NgonFace{3,UInt32}[
            (0, 1, 2),  # First triangle: bottom-left, bottom-right, top-right
            (2, 3, 0)   # Second triangle: top-right, top-left, bottom-left
        ]

        # Generate buffers and create a Vertex Array Object (VAO)
        vao = GLA.VertexArray(
            GLA.generate_buffers(
                image_plot_prog[],
                position=positions,
                texcoord=texcoords
            ),
            indices
        )

        # Use the custom image plot shader with full control
        GLA.bind(image_plot_prog[])

        # Set uniforms for custom image plot shader
        GLA.gluniform(image_plot_prog[], :projection, projection_matrix)
        GLA.gluniform(image_plot_prog[], :use_texture, true)
        GLA.gluniform(image_plot_prog[], :image, 0, texture)

        # Draw the quad
        GLA.bind(vao)
        GLA.draw(vao)
        GLA.unbind(vao)
        GLA.unbind(image_plot_prog[])

    catch e
        @warn "Failed to draw image plot: $e"
    end
end

# Apply colormap and create texture following image component pattern
function apply_colormap_to_matrix(data::Matrix{Float32}, colormap_symbol::Symbol)
    height, width = size(data)

    # Normalize data to [0, 1] range
    min_val, max_val = extrema(data)
    if min_val == max_val
        normalized_data = fill(0.5f0, size(data))
    else
        normalized_data = (data .- min_val) ./ (max_val - min_val)
    end

    # Create RGB texture (3 channels) following image component pattern
    rgb_matrix = Array{Float32}(undef, 3, height, width)

    for i in 1:height, j in 1:width
        # Apply colormap based on the symbol
        r, g, b, a = apply_colormap_rgba(normalized_data[i, j], colormap_symbol)
        rgb_matrix[1, i, j] = r
        rgb_matrix[2, i, j] = g
        rgb_matrix[3, i, j] = b
    end

    return rgb_matrix
end

# Apply colormap based on symbol and normalized value (0-1)
function apply_colormap_rgba(value::Float32, colormap_symbol::Symbol)
    return apply_colormap(value, colormap_symbol)
end

function create_texture_from_matrix(rgb_matrix::Array{Float32,3})
    # Create texture using GLAbstraction following the same pattern as image component
    # Try grayscale first to test if the issue is with 3-channel format
    height, width = size(rgb_matrix)[2:3]
    grayscale_matrix = Array{Float32}(undef, height, width)

    for i in 1:height, j in 1:width
        # Convert RGB to grayscale using standard weights
        grayscale_matrix[i, j] = 0.299f0 * rgb_matrix[1, i, j] + 0.587f0 * rgb_matrix[2, i, j] + 0.114f0 * rgb_matrix[3, i, j]
    end

    return GLA.Texture(grayscale_matrix;
        minfilter=:linear,
        magfilter=:linear,
        x_repeat=:clamp_to_edge,
        y_repeat=:clamp_to_edge
    )
end