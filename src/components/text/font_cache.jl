const font_cache = Dict{Symbol,FreeTypeAbstraction.FTFont}()

"""
    DEFAULT_FONT_PATH

Optional custom path to the default font file. Set this before calling `load_default_font!()` 
if you want to use a specific font file. If not set (nothing), the font will be auto-discovered
from standard locations.

For compiled binaries, fonts are auto-discovered from the bundle directory.

# Example
```julia
Fugl.DEFAULT_FONT_PATH[] = "/path/to/my/font.ttf"
Fugl.load_default_font!()
```
"""
const DEFAULT_FONT_PATH = Ref{Union{Nothing,String}}(nothing)

const DEFAULT_FONT_CACHE_KEY = :__default_font__

"""
    find_font_path()

Find the default font file by checking multiple locations:
1. Custom path in DEFAULT_FONT_PATH[] (if set)
2. Fugl package directory (development/installed)
3. Executable directory (for compiled binaries)
4. Current directory
5. Source directory fallback

Returns nothing if font file cannot be found.
"""
function find_font_path()
    font_name = "FragmentMono-Regular.ttf"

    # First try the custom path if explicitly set
    custom_path = DEFAULT_FONT_PATH[]
    if custom_path !== nothing && isfile(custom_path)
        return custom_path
    end

    # Try in Fugl package directory first (development/installed package)
    # Base.pkgdir gets the root directory of a package
    try
        fugl_root = Base.pkgdir(@__MODULE__)
        if fugl_root !== nothing
            pkg_font_path = joinpath(fugl_root, "assets", "fonts", font_name)
            if isfile(pkg_font_path)
                return pkg_font_path
            end
        end
    catch
        # Fallback if pkgdir fails
    end

    # For compiled binaries, check relative to the executable
    # JuliaC puts the executable in build/bin/, and we want build/share/fonts/
    exe_path = get(ENV, "JULIA_BINDIR", "")
    if exe_path == ""
        exe_path = dirname(Sys.BINDIR)
    end

    # Try ../share/fonts/ relative to bin directory (typical bundle layout)
    if exe_path != ""
        bundle_font_path = joinpath(dirname(exe_path), "share", "fonts", font_name)
        if isfile(bundle_font_path)
            return bundle_font_path
        end

        # Try ./fonts/ relative to bin directory
        bundle_font_path2 = joinpath(exe_path, "fonts", font_name)
        if isfile(bundle_font_path2)
            return bundle_font_path2
        end

        # Try ../assets/fonts/ relative to bin directory
        bundle_font_path3 = joinpath(dirname(exe_path), "assets", "fonts", font_name)
        if isfile(bundle_font_path3)
            return bundle_font_path3
        end
    end

    # Try relative to current directory  
    local_path = joinpath(pwd(), "assets", "fonts", font_name)
    if isfile(local_path)
        return local_path
    end

    # Last resort: check if source path exists (development mode with @__DIR__)

    return nothing
end

"""
    load_default_font!(; safe_mode::Bool = false)

Load the font at `DEFAULT_FONT_PATH` into the font cache as the default font.
This should be called before creating any text components. Users can override 
`DEFAULT_FONT_PATH` before calling this function to use a custom default font.

If `safe_mode` is true, font loading failures are handled gracefully by returning
`nothing` instead of throwing an error. This is useful during static compilation.

# Example
```julia
# Use default font
Fugl.load_default_font!()

# Or use custom font
Fugl.DEFAULT_FONT_PATH[] = "/path/to/my/font.ttf"
Fugl.load_default_font!()

# Safe mode for compilation
Fugl.load_default_font!(safe_mode=true)
```
"""
function load_default_font!(; safe_mode::Bool=false)
    # Try to find font file
    font_path = find_font_path()
    if font_path === nothing
        # Provide helpful error message
        custom_path = DEFAULT_FONT_PATH[]
        search_locations = [
            custom_path !== nothing ? "Custom path: $custom_path" : "Custom path: not set",
            "Fugl package directory (Base.pkgdir)",
            "Executable directory (bin/fonts/, ../share/fonts/, ../assets/fonts/)",
            "Current directory (./assets/fonts/)",
            "Source directory (@__DIR__/../../../assets/fonts/)",
        ]
        error("Failed to find default font FragmentMono-Regular.ttf. Searched:\n" *
              join(["  - " * loc for loc in search_locations], "\n") * "\n" *
              "Set Fugl.DEFAULT_FONT_PATH[] to a valid font file path or ensure font is in bundle.")
    end

    # Verify the file actually exists and is readable
    if !isfile(font_path)
        error("Font path was found but file doesn't exist: $font_path")
    end

    # Try to load the font
    font = FreeTypeAbstraction.try_load(font_path)
    if font === nothing
        # Handle failure based on safe_mode
        if safe_mode
            # During compilation, gracefully handle font loading failure
            @warn "Font loading failed during compilation - this is expected with static compilation" font_path
            return nothing
        else
            # Provide more diagnostic info
            file_size = filesize(font_path)
            file_readable = isreadable(font_path)
            error("Failed to load default font.\n" *
                  "  Path: $font_path\n" *
                  "  Exists: $(isfile(font_path))\n" *
                  "  Readable: $file_readable\n" *
                  "  Size: $file_size bytes\n" *
                  "FreeTypeAbstraction.try_load returned nothing - the font file may be corrupted or in an unsupported format.")
        end
    end
    font_cache[DEFAULT_FONT_CACHE_KEY] = font
    return font
end

"""
    get_default_font(; safe_mode::Bool = false)::Union{FreeTypeAbstraction.FTFont, Nothing}

Get the default font from cache. If not already loaded, calls `load_default_font!()` automatically.
If `safe_mode` is true, returns `nothing` instead of throwing errors during font loading failures.
"""
function get_default_font(; safe_mode::Bool=false)::Union{FreeTypeAbstraction.FTFont,Nothing}
    font = get(font_cache, DEFAULT_FONT_CACHE_KEY, nothing)
    if font === nothing
        return load_default_font!(safe_mode=safe_mode)
    end
    return font
end

"""
    get_font(cache_key::Symbol; safe_mode::Bool = false)::Union{FreeTypeAbstraction.FTFont, Nothing}

Retrieve a font from the cache by its cache key.
Automatically loads the default font if the cache key matches DEFAULT_FONT_CACHE_KEY.
If safe_mode is true, returns nothing instead of throwing errors.
"""
function get_font(cache_key::Symbol; safe_mode::Bool=false)::Union{FreeTypeAbstraction.FTFont,Nothing}
    # Handle default font with auto-loading
    if cache_key === DEFAULT_FONT_CACHE_KEY
        return get_default_font(safe_mode=safe_mode)
    end

    font = get(font_cache, cache_key, nothing)
    if font === nothing
        if safe_mode
            return nothing
        else
            error("Font with cache key '$cache_key' not found in font cache. Make sure to load it first.")
        end
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