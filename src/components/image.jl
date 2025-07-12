struct ImageView <: AbstractView
    horizontal_align::Symbol  # :left, :center, :right
    vertical_align::Symbol    # :top, :middle, :bottom
    width_px::Union{Nothing,Float32}  # Optional hardcoded width
    height_px::Union{Nothing,Float32} # Optional hardcoded height
    texture::Union{Nothing,GLAbstraction.Texture}  # Texture
end

function Image(
    image_path::String;
    horizontal_align=:center,
    vertical_align=:middle,
    width_px::Union{Nothing,Float32}=nothing,
    height_px::Union{Nothing,Float32}=nothing
)::ImageView
    texture = load_image_texture(image_path)
    return ImageView(horizontal_align, vertical_align, width_px, height_px, texture)
end

function measure(view::ImageView)::Tuple{Float32,Float32}
    # Get the original image size from the texture
    texture_width_px, texture_height_px = Float32.(GLA.size(view.texture))

    # Use the provided width and height if specified, otherwise use the texture dimensions
    final_width_px = view.width_px === nothing ? texture_width_px : view.width_px
    final_height_px = view.height_px === nothing ? texture_height_px : view.height_px

    return (final_width_px, final_height_px)
end

function apply_layout(view::ImageView, x::Float32, y::Float32, width::Float32, height::Float32)
    # Get the original image size
    texture_width_px, texture_height_px = Float32.(GLA.size(view.texture))

    # Determine the final width and height
    final_width_px = view.width_px === nothing ? texture_width_px : view.width_px
    final_height_px = view.height_px === nothing ? texture_height_px : view.height_px

    # Shrink proportionally to fit within the container
    scale_factor = min(width / final_width_px, height / final_height_px)
    scaled_width_px = final_width_px * scale_factor
    scaled_height_px = final_height_px * scale_factor

    # Calculate alignment offsets
    horizontal_offset = calculate_horizontal_offset(width, scaled_width_px, view.horizontal_align)
    vertical_offset = calculate_image_vertical_offset(height, scaled_height_px, view.vertical_align)

    # Return the calculated position and size
    return (x + horizontal_offset, y + vertical_offset, scaled_width_px, scaled_height_px)
end

function interpret_view(view::ImageView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    if view.texture === nothing
        return nothing #TODO have some default image or placeholder texture/icon.
    end

    # Calculate the layout
    image_x, image_y, scaled_width_px, scaled_height_px = apply_layout(view, x, y, width, height)

    scale = scaled_width_px / Float32(view.texture.size[1])

    # Render the image
    draw_image(view.texture, image_x, image_y, projection_matrix; scale=scale)
end