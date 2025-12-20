using GLAbstraction: VertexArray, generate_buffers, bind, unbind, draw, gluniform
using ModernGL
using GeometryBasics: Point2f, Vec2, Vec4, NgonFace, Mat4

"""
A component that applies rotation transformation to any child component.
Uses framebuffer rendering and GPU-based rotation for high quality results.
"""
struct RotateView <: AbstractView
    child::AbstractView
    rotation_degrees::Float32
    cache_id::UInt64  # For render caching
end

"""
    Rotate(child::AbstractView; rotation_degrees::Float32=0.0f0)

Create a rotated wrapper around any child component.
Positive angles rotate counter-clockwise.

Uses a framebuffer approach: renders child to texture, then rotates the texture with a custom shader.

# Arguments
- `child`: The child component to rotate
- `rotation_degrees`: Rotation angle in degrees (default: 0.0)
"""
function Rotate(child::AbstractView; rotation_degrees::Float32=0.0f0)
    cache_id = generate_cache_id()
    return RotateView(child, rotation_degrees, cache_id)
end

"""
Calculate the bounding box of a rotated rectangle.
Returns (width, height) of the axis-aligned bounding box.
"""
function calculate_rotated_bounding_box(width::Float32, height::Float32, rotation_degrees::Float32)::Tuple{Float32,Float32}
    if abs(rotation_degrees) < 0.1f0
        return (width, height)
    end

    rotation_rad = rotation_degrees * π / 180.0f0
    cos_rot = abs(cos(rotation_rad))
    sin_rot = abs(sin(rotation_rad))

    # Calculate bounding box of rotated rectangle
    new_width = width * cos_rot + height * sin_rot
    new_height = width * sin_rot + height * cos_rot

    return (new_width, new_height)
end

function measure(view::RotateView)::Tuple{Float32,Float32}
    child_width, child_height = measure(view.child)
    return calculate_rotated_bounding_box(child_width, child_height, view.rotation_degrees)
end

function apply_layout(view::RotateView, x::Float32, y::Float32, width::Float32, height::Float32)
    # The rotated view takes the full area provided
    return (x, y, width, height)
end

function interpret_view(view::RotateView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32)
    # If no rotation, render child directly
    if abs(view.rotation_degrees) < 0.1f0
        child_width, child_height = measure(view.child)
        child_x = x + (width - child_width) / 2.0f0
        child_y = y + (height - child_height) / 2.0f0
        interpret_view(view.child, child_x, child_y, child_width, child_height, projection_matrix, mouse_x, mouse_y)
        return
    end

    # Get render cache
    cache = get_render_cache(view.cache_id)

    # Get child dimensions
    child_width, child_height = measure(view.child)

    # Calculate content hash for cache invalidation
    content_hash = hash((view.rotation_degrees, child_width, child_height, hash(view.child)))

    # Cache dimensions - use exact pixel dimensions matching the child size
    cache_width = Int32(round(child_width))
    cache_height = Int32(round(child_height))

    # Check if we need to redraw
    bounds = (x, y, Float32(cache_width), Float32(cache_height))
    needs_redraw = should_invalidate_cache(cache, content_hash, bounds)

    if needs_redraw || !cache.is_valid
        # Create new framebuffer if needed
        if cache.framebuffer === nothing || cache.cache_width != cache_width || cache.cache_height != cache_height
            (framebuffer, color_texture, depth_texture) = create_render_framebuffer(cache_width, cache_height; with_depth=false)
            update_cache!(cache, framebuffer, color_texture, depth_texture, content_hash, bounds)
        else
            # Update cache with existing framebuffer
            update_cache!(cache, cache.framebuffer, cache.color_texture, cache.depth_texture, content_hash, bounds)
        end

        # Render child to framebuffer
        render_child_to_framebuffer(view, cache, child_width, child_height)
        cache.is_valid = true
    end

    # Draw rotated texture to screen
    if cache.is_valid && cache.color_texture !== nothing
        draw_rotated_texture(cache.color_texture, view.rotation_degrees, x, y, width, height, child_width, child_height, projection_matrix)
    end
end

"""
Render the child component to the framebuffer
"""
function render_child_to_framebuffer(view::RotateView, cache::RenderCache, child_width::Float32, child_height::Float32)
    # Push framebuffer and viewport
    push_framebuffer!(cache.framebuffer)
    push_viewport!(Int32(0), Int32(0), cache.cache_width, cache.cache_height)

    try
        # Clear framebuffer with transparent background
        ModernGL.glClearColor(0.0f0, 0.0f0, 0.0f0, 0.0f0)
        ModernGL.glClear(ModernGL.GL_COLOR_BUFFER_BIT)

        # Create simple projection matrix for exact pixel mapping
        fb_projection = get_orthographic_matrix(0.0f0, child_width, child_height, 0.0f0, -1.0f0, 1.0f0)

        # Render child at its natural size for crisp rendering
        interpret_view(view.child, 0.0f0, 0.0f0, child_width, child_height, fb_projection, 0.0f0, 0.0f0)
    finally
        pop_viewport!()
        pop_framebuffer!()
    end
end

"""
Draw a texture with rotation applied via shader
"""
function draw_rotated_texture(texture_id::UInt32, rotation_degrees::Float32, x::Float32, y::Float32,
    width::Float32, height::Float32, texture_width::Float32, texture_height::Float32,
    projection_matrix::Mat4{Float32})

    # Calculate center position for rotation
    center_x = x + width / 2.0f0
    center_y = y + height / 2.0f0

    # Calculate texture position (centered in the rotated bounds)
    tex_x = center_x - texture_width / 2.0f0
    tex_y = center_y - texture_height / 2.0f0

    # Convert rotation to radians
    rotation_rad = rotation_degrees * π / 180.0f0
    cos_rot = cos(rotation_rad)
    sin_rot = sin(rotation_rad)

    # Create rotated quad vertices around center
    half_width = texture_width / 2.0f0
    half_height = texture_height / 2.0f0

    # Define corners relative to center
    corners = [
        (-half_width, -half_height),  # Bottom-left
        (half_width, -half_height),   # Bottom-right  
        (half_width, half_height),    # Top-right
        (-half_width, half_height)    # Top-left
    ]

    # Rotate corners and translate to final position
    positions = Point2f[]
    for (local_x, local_y) in corners
        # Apply rotation
        rotated_x = local_x * cos_rot - local_y * sin_rot
        rotated_y = local_x * sin_rot + local_y * cos_rot

        # Translate to center position
        final_x = center_x + rotated_x
        final_y = center_y + rotated_y

        # For 90° rotations, snap to pixel boundaries for crisp rendering
        if abs(rotation_degrees % 90.0f0) < 0.1f0
            final_x = round(final_x)
            final_y = round(final_y)
        end

        push!(positions, Point2f(final_x, final_y))
    end

    # Texture coordinates
    texturecoordinates = Vec2{Float32}[
        Vec2{Float32}(0.0f0, 1.0f0),  # Bottom-left
        Vec2{Float32}(1.0f0, 1.0f0),  # Bottom-right
        Vec2{Float32}(1.0f0, 0.0f0),  # Top-right
        Vec2{Float32}(0.0f0, 0.0f0)   # Top-left
    ]

    # Colors (white for texture)
    colors = Vec4{Float32}[Vec4{Float32}(1.0f0, 1.0f0, 1.0f0, 1.0f0) for _ in 1:4]

    # Triangle indices
    elements = NgonFace{3,UInt32}[
        (0, 1, 2),  # First triangle
        (2, 3, 0)   # Second triangle
    ]

    # Create VAO
    buffers = GLA.generate_buffers(prog[], position=positions, texcoord=texturecoordinates, color=colors)
    vao = GLA.VertexArray(buffers, elements)

    # Render
    GLA.bind(prog[])
    GLA.gluniform(prog[], :use_texture, true)

    # Bind texture with appropriate filtering
    ModernGL.glActiveTexture(ModernGL.GL_TEXTURE0)
    ModernGL.glBindTexture(ModernGL.GL_TEXTURE_2D, texture_id)

    # Use nearest neighbor filtering for exact 90° rotations to maintain crispness
    # Use linear filtering for other angles to smooth interpolation
    if abs(rotation_degrees % 90.0f0) < 0.1f0
        ModernGL.glTexParameteri(ModernGL.GL_TEXTURE_2D, ModernGL.GL_TEXTURE_MIN_FILTER, ModernGL.GL_NEAREST)
        ModernGL.glTexParameteri(ModernGL.GL_TEXTURE_2D, ModernGL.GL_TEXTURE_MAG_FILTER, ModernGL.GL_NEAREST)
    else
        ModernGL.glTexParameteri(ModernGL.GL_TEXTURE_2D, ModernGL.GL_TEXTURE_MIN_FILTER, ModernGL.GL_LINEAR)
        ModernGL.glTexParameteri(ModernGL.GL_TEXTURE_2D, ModernGL.GL_TEXTURE_MAG_FILTER, ModernGL.GL_LINEAR)
    end

    GLA.gluniform(prog[], :image, Int32(0))
    GLA.gluniform(prog[], :projection, projection_matrix)

    # Draw
    GLA.bind(vao)
    GLA.draw(vao)

    # Cleanup
    GLA.unbind(vao)
    GLA.unbind(prog[])
    ModernGL.glBindTexture(ModernGL.GL_TEXTURE_2D, 0)
end
