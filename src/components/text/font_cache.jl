const font_cache = Dict{Symbol,FreeTypeAbstraction.FTFont}()

"""
    DEFAULT_FONT_PATH

Path to the default font file. Users can override this before calling `load_default_font!()` 
to use a custom font throughout their application.

# Example
```julia
Fugl.DEFAULT_FONT_PATH[] = "/path/to/my/font.ttf"
Fugl.load_default_font!()
```
"""
const DEFAULT_FONT_PATH = Ref(joinpath(@__DIR__, "../../../assets/fonts/FragmentMono-Regular.ttf"))

const DEFAULT_FONT_CACHE_KEY = :__default_font__

"""
    load_default_font!()

Load the font at `DEFAULT_FONT_PATH` into the font cache as the default font.
This should be called before creating any text components. Users can override 
`DEFAULT_FONT_PATH` before calling this function to use a custom default font.

# Example
```julia
# Use default font
Fugl.load_default_font!()

# Or use custom font
Fugl.DEFAULT_FONT_PATH[] = "/path/to/my/font.ttf"
Fugl.load_default_font!()
```
"""
function load_default_font!()
    font_path = DEFAULT_FONT_PATH[]
    font = FreeTypeAbstraction.try_load(font_path)
    if font === nothing
        error("Failed to load default font at path: $font_path")
    end
    font_cache[DEFAULT_FONT_CACHE_KEY] = font
    return font
end

"""
    get_default_font()::FreeTypeAbstraction.FTFont

Get the default font from cache. If not already loaded, calls `load_default_font!()` automatically.
"""
function get_default_font()::FreeTypeAbstraction.FTFont
    font = get(font_cache, DEFAULT_FONT_CACHE_KEY, nothing)
    if font === nothing
        return load_default_font!()
    end
    return font
end

"""
    get_font(cache_key::Symbol)::FreeTypeAbstraction.FTFont

Retrieve a font from the cache by its cache key.
Automatically loads the default font if the cache key matches DEFAULT_FONT_CACHE_KEY.
Throws an error if the font is not found in the cache.
"""
function get_font(cache_key::Symbol)::FreeTypeAbstraction.FTFont
    # Handle default font with auto-loading
    if cache_key === DEFAULT_FONT_CACHE_KEY
        return get_default_font()
    end

    font = get(font_cache, cache_key, nothing)
    if font === nothing
        error("Font with cache key '$cache_key' not found in font cache. Make sure to load it first.")
    end
    return font
end

"""
    get_font_by_path(cache_key::Symbol, font_path::String)::FreeTypeAbstraction.FTFont

Load a font from a file path and cache it with the specified key.
If already cached with this key, returns the cached font.

# Example
```julia
# Load a custom font with an explicit cache key
get_font_by_path(:my_title_font, "/path/to/font.ttf")
style = TextStyle(font_cache_key=:my_title_font, size_px=32)
```
"""
function get_font_by_path(cache_key::Symbol, font_path::String)::FreeTypeAbstraction.FTFont
    # Check if already cached
    font = get(font_cache, cache_key, nothing)
    if font !== nothing
        return font
    end

    # Load the font and cache it
    font = FreeTypeAbstraction.try_load(font_path)
    if font === nothing
        error("Failed to load font at path: $font_path")
    end

    font_cache[cache_key] = font
    return font
end

"""
    get_font_by_name(cache_key::Symbol, font_name::String)::FreeTypeAbstraction.FTFont

Find and load a system font by name, caching it with the specified key.
If already cached with this key, returns the cached font.

# Example
```julia
# Load a system font
get_font_by_name(:my_system_font, "Arial")
style = TextStyle(font_cache_key=:my_system_font, size_px=16)
```
"""
function get_font_by_name(cache_key::Symbol, font_name::String)::FreeTypeAbstraction.FTFont
    # Check if already cached
    font = get(font_cache, cache_key, nothing)
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

    font_cache[cache_key] = font
    return font
end

function clear_font_cache!()
    # Clear the font cache
    empty!(font_cache)
end