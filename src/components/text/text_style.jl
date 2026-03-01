struct TextStyle
    font_cache_key::Symbol
    size_px::Int
    color::Vec4{Float32}  # RGBA color
end

"""
    get_font(style::TextStyle)::Union{FreeTypeAbstraction.FTFont, Nothing}

Retrieve the font associated with a TextStyle from the font cache.
Returns nothing if font is not available (e.g., during static compilation).
"""
function get_font(style::TextStyle)::Union{FreeTypeAbstraction.FTFont,Nothing}
    return get_font(style.font_cache_key, safe_mode=true)
end

"""
    TextStyle(; font_cache_key=DEFAULT_FONT_CACHE_KEY, size_px=16, color=Vec{4,Float32}(0.0, 0.0, 0.0, 1.0))

Create a TextStyle with the specified font cache key, size, and color.

The font referenced by the cache key should already be loaded into the font cache.
By default, uses the default font cache key (a Symbol for optimal performance).

# Example
```julia
# Use default font
style = TextStyle(size_px=20)

# Use a custom font
Fugl.get_font_by_path(:my_font, "/path/to/font.ttf")
style = TextStyle(font_cache_key=:my_font, size_px=20)
```
"""
function TextStyle(;
    font_cache_key::Symbol=DEFAULT_FONT_CACHE_KEY,
    size_px=16,
    color=Vec{4,Float32}(0.0, 0.0, 0.0, 1.0),
)
    return TextStyle(font_cache_key, size_px, color)
end

"""
Copy constructor for TextStyle that allows overriding specific fields.
"""
function TextStyle(base::TextStyle;
    font_cache_key=base.font_cache_key,
    size_px=base.size_px,
    color=base.color
)
    return TextStyle(font_cache_key, size_px, color)
end

"""
    measure_word_width_cached(style::TextStyle, word::AbstractString)::Float32

Measure the width of a word using a TextStyle. Convenience function that extracts the font and size from the style.
Returns fallback width if font is not available (e.g., during static compilation).
"""
function measure_word_width_cached(style::TextStyle, word::AbstractString)::Float32
    font = get_font(style)
    if font === nothing
        # Fallback measurement during compilation
        return Float32(length(word) * style.size_px * 0.6)  # Approximate monospace width
    end
    return measure_word_width_cached(font, word, style.size_px)
end

"""
    measure_word_width(style::TextStyle, word::AbstractString)::Float32

Measure the width of a word using a TextStyle. Convenience function that extracts the font and size from the style.
Returns fallback width if font is not available (e.g., during static compilation).
"""
function measure_word_width(style::TextStyle, word::AbstractString)::Float32
    font = get_font(style)
    if font === nothing
        # Fallback measurement during compilation
        return Float32(length(word) * style.size_px * 0.6)  # Approximate monospace width
    end
    return measure_word_width(font, word, style.size_px)
end