"""
A structure to hold batched glyph data for efficient rendering.
Each glyph becomes two triangles (6 vertices) in the batch.
Inspired by Makie.jl's TextureAtlas approach.
"""
struct GlyphBatch
    positions::Vector{Point2f}
    texture_coords::Vector{Vec2f}
    indices::Vector{UInt32}
end

function GlyphBatch()
    return GlyphBatch(
        Vector{Point2f}(),
        Vector{Vec2f}(),
        Vector{UInt32}()
    )
end

"""
Clear all data from a glyph batch to reuse it.
"""
function clear_batch!(batch::GlyphBatch)
    empty!(batch.positions)
    empty!(batch.texture_coords)
    empty!(batch.indices)
end

"""
Add a single rotated glyph to the batch. Each glyph quad is rotated around its lower-left corner
and positioned along a rotated baseline.
"""
function add_rotated_glyph_to_batch!(
    batch::GlyphBatch,
    x_px::Float32, y_px::Float32,
    width::Float32, height::Float32,
    u_min::Float32, v_min::Float32, u_max::Float32, v_max::Float32,
    rotation_rad::Float32
)
    # Calculate the current vertex offset
    vertex_offset = UInt32(length(batch.positions))

    # Calculate rotation around lower-left corner (x_px, y_px)
    cos_rot = cos(rotation_rad)
    sin_rot = sin(rotation_rad)

    # The lower-left corner (x_px, y_px) is our rotation origin
    origin_x = x_px
    origin_y = y_px

    # Define local quad vertices relative to lower-left corner
    local_vertices = [
        (0.0f0, height),      # Top-left
        (width, height),      # Top-right
        (width, 0.0f0),       # Bottom-right
        (0.0f0, 0.0f0)        # Bottom-left
    ]

    # Rotate and translate vertices
    for (local_x, local_y) in local_vertices
        # Apply rotation around origin
        rotated_x = local_x * cos_rot - local_y * sin_rot
        rotated_y = local_x * sin_rot + local_y * cos_rot

        # Translate to final position
        final_x = origin_x + rotated_x
        final_y = origin_y + rotated_y

        push!(batch.positions, Point2f(final_x, final_y))
    end

    # Add texture coordinates (same order as vertices)
    push!(batch.texture_coords, Vec2f(u_min, v_max))  # Top-left
    push!(batch.texture_coords, Vec2f(u_max, v_max))  # Top-right
    push!(batch.texture_coords, Vec2f(u_max, v_min))  # Bottom-right
    push!(batch.texture_coords, Vec2f(u_min, v_min))  # Bottom-left

    # Add indices for two triangles
    push!(batch.indices, vertex_offset + 0, vertex_offset + 1, vertex_offset + 2)  # First triangle
    push!(batch.indices, vertex_offset + 2, vertex_offset + 3, vertex_offset + 0)  # Second triangle
end

"""
Add a single glyph to the batch. This is much more efficient than individual rendering.
"""
function add_glyph_to_batch!(
    batch::GlyphBatch,
    x_px::Float32, y_px::Float32,
    width::Float32, height::Float32,
    u_min::Float32, v_min::Float32, u_max::Float32, v_max::Float32
)
    # Calculate the current vertex offset
    vertex_offset = UInt32(length(batch.positions))

    # Add vertices for this glyph (4 vertices for a quad)
    push!(batch.positions, Point2f(x_px, y_px + height))           # Top-left
    push!(batch.positions, Point2f(x_px + width, y_px + height))   # Top-right
    push!(batch.positions, Point2f(x_px + width, y_px))            # Bottom-right
    push!(batch.positions, Point2f(x_px, y_px))                    # Bottom-left

    # Add texture coordinates
    push!(batch.texture_coords, Vec2f(u_min, v_max))  # Top-left
    push!(batch.texture_coords, Vec2f(u_max, v_max))  # Top-right
    push!(batch.texture_coords, Vec2f(u_max, v_min))  # Bottom-right
    push!(batch.texture_coords, Vec2f(u_min, v_min))  # Bottom-left

    # Add indices for two triangles
    push!(batch.indices, vertex_offset + 0, vertex_offset + 1, vertex_offset + 2)  # First triangle
    push!(batch.indices, vertex_offset + 2, vertex_offset + 3, vertex_offset + 0)  # Second triangle
end

# Global batch for reuse across text rendering calls to minimize allocations
const GLOBAL_TEXT_BATCH = Ref{Union{Nothing,GlyphBatch}}(nothing)

function get_global_text_batch()
    if GLOBAL_TEXT_BATCH[] === nothing
        GLOBAL_TEXT_BATCH[] = GlyphBatch()
    end
    return GLOBAL_TEXT_BATCH[]
end

"""
Clear the global text batch to free memory.
"""
function clear_text_batch!()
    GLOBAL_TEXT_BATCH[] = nothing
end