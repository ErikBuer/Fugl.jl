const font_cache = IdDict{String,FreeTypeAbstraction.FTFont}()

function get_font_by_path(font_path::String)::FreeTypeAbstraction.FTFont
    # Retrieve the font directly or load it if not cached
    font = get(font_cache, font_path, nothing)
    if font !== nothing
        return font
    end

    # Load the font and cache it
    font = FreeTypeAbstraction.try_load(font_path)
    if font === nothing
        error("Failed to load font at path: $font_path")
    end

    font_cache[font_path] = font
    return font
end

function get_font_by_name(font_name::String)::FreeTypeAbstraction.FTFont
    # Retrieve the font directly or load it if not cached
    font = get(font_cache, font_name, nothing)
    if font !== nothing
        return font
    end

    # Find the font path and load the font
    font_path = FreeTypeAbstraction.findfont(font_name)
    if font_path === nothing
        error("Font '$font_name' not found.")
    end

    font = FreeTypeAbstraction.try_load(font_path)
    if font === nothing
        error("Failed to load font '$font_name' at path: $font_path")
    end

    font_cache[font_name] = font
    return font
end

function clear_font_cache!()
    # Clear the font cache
    empty!(font_cache)
end