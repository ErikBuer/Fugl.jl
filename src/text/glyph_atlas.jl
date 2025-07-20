"""
Unique identifier for a glyph at a specific size and font.
"""
struct GlyphKey
    font_hash::UInt64
    char::Char
    pixelsize::Int
end

"""
UV coordinates and dimensions for a glyph in the atlas.
"""
struct GlyphUV
    u_min::Float32
    v_min::Float32
    u_max::Float32
    v_max::Float32
    width::Int
    height::Int
    bearing_x::Float32
    bearing_y::Float32
    advance::Float32
end

"""
A texture atlas that stores multiple glyphs in a single OpenGL texture.
This dramatically speeds up text rendering by avoiding texture creation per glyph.
"""
mutable struct GlyphAtlas
    texture::GLAbstraction.Texture{Float32,2}
    width::Int
    height::Int
    current_x::Int
    current_y::Int
    row_height::Int
    glyph_cache::Dict{GlyphKey,GlyphUV}
    atlas_data::Matrix{Float32}
end

# Global glyph atlas instance (now defined after the struct)
const GLYPH_ATLAS = Ref{Union{Nothing,GlyphAtlas}}(nothing)

function Base.hash(key::GlyphKey, h::UInt)
    return hash(key.font_hash, hash(key.char, hash(key.pixelsize, h)))
end

function Base.:(==)(a::GlyphKey, b::GlyphKey)
    return a.font_hash == b.font_hash && a.char == b.char && a.pixelsize == b.pixelsize
end

"""
    get_glyph_atlas() -> GlyphAtlas

Get the global glyph atlas, creating it if it doesn't exist.
"""
function get_glyph_atlas()
    if GLYPH_ATLAS[] === nothing
        GLYPH_ATLAS[] = create_glyph_atlas()
    end
    return GLYPH_ATLAS[]
end

"""
    create_glyph_atlas(width=2048, height=2048) -> GlyphAtlas

Create a new glyph atlas texture.
"""
function create_glyph_atlas(width::Int=2048, height::Int=2048)
    # Create empty texture data
    atlas_data = zeros(Float32, width, height)

    # Create OpenGL texture
    texture = GLAbstraction.Texture(
        atlas_data;
        minfilter=:linear,
        magfilter=:linear,
        x_repeat=:clamp_to_edge,
        y_repeat=:clamp_to_edge
    )

    return GlyphAtlas(
        texture,
        width,
        height,
        1,        # current_x (start at 1 for Julia 1-based indexing)
        1,        # current_y (start at 1 for Julia 1-based indexing)
        0,        # row_height
        Dict{GlyphKey,GlyphUV}(),
        atlas_data
    )
end

"""
    get_font_hash(font::FreeTypeAbstraction.FTFont) -> UInt64

Get a unique hash for a font face.
"""
function get_font_hash(font::FreeTypeAbstraction.FTFont)
    # Use a more stable identifier based on the font file path and face properties
    # This should be consistent across font cache retrievals
    font_path = ""
    try
        # Try to get the font file path if available
        font_path = font.face.family_name * "_" * font.face.style_name
    catch
        # Fallback to pointer-based hash if face info is not available
        font_path = string(font.ft_ptr)
    end
    return hash((font_path, font.face_index))
end

"""
    get_or_insert_glyph!(atlas::GlyphAtlas, font, char, pixelsize) -> GlyphUV

Get glyph UV coordinates from atlas, inserting the glyph if not present.
"""
function get_or_insert_glyph!(atlas::GlyphAtlas, font::FreeTypeAbstraction.FTFont, char::Char, pixelsize::Int)
    key = GlyphKey(get_font_hash(font), char, pixelsize)

    # Return cached glyph if it exists
    if haskey(atlas.glyph_cache, key)
        return atlas.glyph_cache[key]
    end

    # Render the glyph
    bitmap, extent = FreeTypeAbstraction.renderface(font, char, pixelsize)

    # Handle empty glyphs (like spaces)
    if isempty(bitmap) || size(bitmap, 1) == 0 || size(bitmap, 2) == 0
        glyph_uv = GlyphUV(
            0.0f0, 0.0f0, 0.0f0, 0.0f0,  # UV coordinates (empty)
            0, 0,                         # width, height
            Float32(extent.horizontal_bearing[1]),
            Float32(extent.horizontal_bearing[2]),
            Float32(extent.advance[1])
        )
        atlas.glyph_cache[key] = glyph_uv
        return glyph_uv
    end

    # Get bitmap dimensions
    glyph_width, glyph_height = size(bitmap)

    # Check if we need to move to next row
    if atlas.current_x + glyph_width > atlas.width
        atlas.current_x = 1  # Reset to 1 for Julia indexing
        atlas.current_y += atlas.row_height
        atlas.row_height = glyph_height  # Start new row with current glyph height
    else
        # Update row height for current row
        atlas.row_height = max(atlas.row_height, glyph_height)
    end

    # Check if atlas is full
    if atlas.current_y + glyph_height > atlas.height
        @warn "Glyph atlas is full! Consider increasing atlas size or implementing atlas expansion."
        # For now, return a default UV that won't crash
        glyph_uv = GlyphUV(
            0.0f0, 0.0f0, 0.0f0, 0.0f0,
            0, 0,
            Float32(extent.horizontal_bearing[1]),
            Float32(extent.horizontal_bearing[2]),
            Float32(extent.advance[1])
        )
        atlas.glyph_cache[key] = glyph_uv
        return glyph_uv
    end

    # Insert glyph into atlas
    x_start = atlas.current_x
    y_start = atlas.current_y

    # Copy bitmap data to atlas (convert to Float32 and normalize)
    # Both atlas.atlas_data and bitmap use 1-based indexing in Julia
    # Store as grayscale values that the glyph shader can use as alpha
    for y in 1:glyph_height, x in 1:glyph_width
        if x_start + x - 1 <= atlas.width && y_start + y - 1 <= atlas.height
            # Normalize the bitmap value to [0, 1] range for alpha
            alpha_value = Float32(bitmap[x, y]) / 255.0f0
            atlas.atlas_data[x_start+x-1, y_start+y-1] = alpha_value
        end
    end

    # Update atlas texture - use 0-based coordinates for OpenGL
    # Extract the glyph data we just inserted
    glyph_data = atlas.atlas_data[x_start:x_start+glyph_width-1, y_start:y_start+glyph_height-1]

    # Convert to 0-based coordinates for OpenGL
    gl_x_start = x_start - 1
    gl_y_start = y_start - 1

    GLAbstraction.texsubimage(
        atlas.texture,
        glyph_data,
        gl_x_start+1:gl_x_start+glyph_width,
        gl_y_start+1:gl_y_start+glyph_height
    )

    # Calculate UV coordinates (normalized coordinates for OpenGL)
    u_min = Float32(x_start - 1) / Float32(atlas.width)
    v_min = Float32(y_start - 1) / Float32(atlas.height)
    u_max = Float32(x_start - 1 + glyph_width) / Float32(atlas.width)
    v_max = Float32(y_start - 1 + glyph_height) / Float32(atlas.height)

    # Create glyph UV
    glyph_uv = GlyphUV(
        u_min, v_min, u_max, v_max,
        glyph_width, glyph_height,
        Float32(extent.horizontal_bearing[1]),
        Float32(extent.horizontal_bearing[2]),
        Float32(extent.advance[1])
    )

    # Debug: Validate the glyph UV we just created
    if u_min >= u_max || v_min >= v_max
        @warn "Created invalid UV coordinates for '$char': ($u_min, $v_min) -> ($u_max, $v_max)"
        @warn "Position: ($x_start, $y_start), Size: $(glyph_width)x$(glyph_height)"
        @warn "Atlas: $(atlas.width)x$(atlas.height)"
    end


    # Update atlas state - move to next position in current row
    atlas.current_x += glyph_width
    # row_height is already updated above when placing the glyph

    # Cache the glyph
    atlas.glyph_cache[key] = glyph_uv

    return glyph_uv
end

"""
    clear_glyph_atlas!()

Clear the global glyph atlas cache.
"""
function clear_glyph_atlas!()
    if GLYPH_ATLAS[] !== nothing
        empty!(GLYPH_ATLAS[].glyph_cache)
        GLYPH_ATLAS[].current_x = 1  # Reset to 1 for Julia indexing
        GLYPH_ATLAS[].current_y = 1  # Reset to 1 for Julia indexing
        GLYPH_ATLAS[].row_height = 0
        fill!(GLYPH_ATLAS[].atlas_data, 0.0f0)
        # Update the texture with cleared data (convert to 0-based coordinates for OpenGL)
        GLAbstraction.texsubimage(
            GLYPH_ATLAS[].texture,
            GLYPH_ATLAS[].atlas_data,
            0:(GLYPH_ATLAS[].width-1),
            0:(GLYPH_ATLAS[].height-1)
        )
    end
end
