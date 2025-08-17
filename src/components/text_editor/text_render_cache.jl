using GeometryBasics: Mat4

"""
Generate a content hash for text components (TextBox/CodeEditor) that captures all rendering-relevant state
"""
function hash_text_content(text::String, style::Any, is_focused::Bool, cursor_pos::Any, selection::Any)::UInt64
    h = hash(text)
    h = hash(is_focused, h)

    # Hash cursor position if present
    if cursor_pos !== nothing
        h = hash((cursor_pos.line, cursor_pos.column), h)
    end

    # Hash selection if present
    if selection !== nothing && selection !== (nothing, nothing)
        h = hash(selection, h)
    end

    # Hash relevant style properties that affect rendering
    h = hash((
            style.text_style.size_px,
            style.text_style.color,
            style.background_color_focused,
            style.background_color_unfocused,
            style.border_color,
            style.border_width_px,
            style.corner_radius_px,
            style.padding_px,
            style.cursor_color,
            style.selection_color
        ), h)

    return h
end

"""
Get text render cache using a content-based cache key
"""
function get_text_render_cache(text::String, style::Any, component_type::Symbol)::Tuple{Any,RenderCache}
    # Create cache key based on component type and style (but not content)
    # This allows sharing caches between similar text components with different content
    style_hash = hash((
        component_type,
        style.text_style.size_px,
        style.text_style.font,
        style.background_color_focused,
        style.background_color_unfocused,
        style.border_color,
        style.border_width_px,
        style.corner_radius_px,
        style.padding_px
    ))

    cache_key = (component_type, style_hash)
    cache = get_render_cache(cache_key)
    return cache_key, cache
end

"""
Check if text component cache should be invalidated
"""
function should_invalidate_text_cache(text::String, style::Any, is_focused::Bool, cursor_pos::Any, selection::Any, bounds::Tuple{Float32,Float32,Float32,Float32}, component_type::Symbol)::Bool
    # Generate content hash for the text component
    content_hash = hash_text_content(text, style, is_focused, cursor_pos, selection)

    # Get the cache
    cache_key, cache = get_text_render_cache(text, style, component_type)

    # Use generic cache invalidation logic
    return should_invalidate_cache(cache, content_hash, bounds)
end

"""
Create framebuffer for text rendering (no depth needed)
"""
function create_text_framebuffer(width::Int32, height::Int32)::Tuple{UInt32,UInt32,Union{UInt32,Nothing}}
    return create_render_framebuffer(width, height; with_depth=false)
end

"""
Draw cached text texture to screen
"""
function draw_cached_text_texture(texture_id::UInt32, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    draw_cached_texture(texture_id, x, y, width, height, projection_matrix)
end
