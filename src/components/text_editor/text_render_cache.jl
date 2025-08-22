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
Check if text component cache should be invalidated
"""
function should_invalidate_text_cache(text::String, style::Any, is_focused::Bool, cursor_pos::Any, selection::Any, bounds::Tuple{Float32,Float32,Float32,Float32}, state)::Bool
    # Generate content hash for the text component
    content_hash = hash_text_content(text, style, is_focused, cursor_pos, selection)

    # Get the cache using state's cache ID
    cache = get_render_cache(state.cache_id)

    # Use generic cache invalidation logic
    return should_invalidate_cache(cache, content_hash, bounds)
end
