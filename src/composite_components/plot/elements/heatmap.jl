struct HeatmapElement <: AbstractPlotElement
    data::Matrix{Float32}
    x_range::Tuple{Float32,Float32}  # (min_x, max_x)
    y_range::Tuple{Float32,Float32}  # (min_y, max_y)
    colormap::Symbol  # :viridis, :plasma, :grayscale, etc.
    nan_color::Tuple{Float32,Float32,Float32,Float32}  # Color for NaN/invalid values
    background_color::Tuple{Float32,Float32,Float32,Float32}  # Background color
    value_range::Tuple{Float32,Float32}  # For color normalization
end

function HeatmapElement(
    data::Matrix{<:Real};
    x_range::Tuple{Real,Real}=(1, size(data, 2)),
    y_range::Tuple{Real,Real}=(1, size(data, 1)),
    colormap::Symbol=:viridis,
    nan_color::Tuple{Real,Real,Real,Real}=(1.0, 0.0, 1.0, 1.0),  # Magenta for NaN
    background_color::Tuple{Real,Real,Real,Real}=(0.0, 0.0, 0.0, 1.0),  # Black background
    value_range::Union{Nothing,Tuple{Real,Real}}=nothing
)
    data_f32 = Float32.(data)
    x_range_f32 = (Float32(x_range[1]), Float32(x_range[2]))
    y_range_f32 = (Float32(y_range[1]), Float32(y_range[2]))
    nan_color_f32 = (Float32(nan_color[1]), Float32(nan_color[2]), Float32(nan_color[3]), Float32(nan_color[4]))
    background_color_f32 = (Float32(background_color[1]), Float32(background_color[2]), Float32(background_color[3]), Float32(background_color[4]))

    # Auto-detect value range if not provided
    if value_range === nothing
        min_val, max_val = extrema(data_f32)
        value_range_f32 = (min_val, max_val)
    else
        value_range_f32 = (Float32(value_range[1]), Float32(value_range[2]))
    end

    return HeatmapElement(data_f32, x_range_f32, y_range_f32, colormap, nan_color_f32, background_color_f32, value_range_f32)
end

# Draw image plot using texture and existing shader - much more efficient!
function draw_image_plot(
    element::HeatmapElement,
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
    element::HeatmapElement,
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
    element::HeatmapElement,
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
    element::HeatmapElement,
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
        matrix_data = apply_colormap_to_matrix(element.data, element.colormap)

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

        # Define the elements (two triangles forming the rectangle)
        indices = NgonFace{3,UInt32}[
            (0, 1, 2),  # First triangle: bottom-left, bottom-right, top-right
            (2, 3, 0)   # Second triangle: top-right, top-left, bottom-left
        ]

        # Generate buffers and create a Vertex Array Object (VAO)
        vao = GLA.VertexArray(
            GLA.generate_buffers(
                image_plot_prog[],  # Use extended heatmap shader
                position=positions,
                texcoord=texcoords
            ),
            indices
        )

        # Use the extended heatmap shader
        GLA.bind(image_plot_prog[])

        # Set all uniforms including extended ones
        GLA.gluniform(image_plot_prog[], :use_texture, true)
        GLA.gluniform(image_plot_prog[], :image, 0, texture)
        GLA.gluniform(image_plot_prog[], :projection, projection_matrix)
        GLA.gluniform(image_plot_prog[], :value_range, Vec2f(element.value_range))
        GLA.gluniform(image_plot_prog[], :nan_color, Vec4f(element.nan_color))
        GLA.gluniform(image_plot_prog[], :background_color, Vec4f(element.background_color))
        GLA.gluniform(image_plot_prog[], :colormap_type, colormap_to_int(element.colormap))

        # Draw the quad
        GLA.bind(vao)
        GLA.draw(vao)
        GLA.unbind(vao)
        GLA.unbind(image_plot_prog[])

    catch e
        @warn "Failed to draw heatmap: $e"
    end
end

# Apply colormap and create texture
function apply_colormap_to_matrix(data::Matrix{Float32}, colormap_symbol::Symbol)
    height, width = size(data)

    # Find valid (non-NaN) values for normalization
    valid_data = data[.!isnan.(data)]

    if isempty(valid_data)
        # All NaN data - use special value to indicate NaN in texture
        normalized_data = fill(-1.0f0, size(data))  # Use -1 to indicate NaN
    else
        min_val, max_val = extrema(valid_data)

        if min_val == max_val
            normalized_data = fill(0.5f0, size(data))
        else
            normalized_data = similar(data)
            for i in eachindex(data)
                if isnan(data[i])
                    normalized_data[i] = -1.0f0  # Special value for NaN
                else
                    normalized_data[i] = (data[i] - min_val) / (max_val - min_val)
                end
            end
        end
    end

    # Always return normalized grayscale data - colormap will be applied in shader
    return normalized_data
end

function create_texture_from_matrix(matrix_data::Matrix{Float32})
    # Always create grayscale texture - colormap applied in shader
    texture = GLA.Texture(matrix_data;
        minfilter=:nearest,
        magfilter=:nearest,
        x_repeat=:clamp_to_edge,
        y_repeat=:clamp_to_edge
    )
    return texture
end

# Convert colormap symbol to integer for shader uniform
function colormap_to_int(colormap::Symbol)::Int32
    if colormap == :grayscale
        return 0
    elseif colormap == :viridis
        return 1
    elseif colormap == :plasma
        return 2
    elseif colormap == :hot
        return 3
    else
        return 0  # Default to grayscale
    end
end