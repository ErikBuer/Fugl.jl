"""
Simple DPI scaling state for the current rendering context.
Only manual scaling - no automatic system DPI detection.
"""
mutable struct DPIScaling
    logical_width::Float32   # Window size in logical coordinates
    logical_height::Float32
    pixel_width::Float32     # Framebuffer size in actual pixels
    pixel_height::Float32
    manual_scale::Float32    # User-controlled scaling multiplier (1.0 = 1 point = 1 pixel)
end

# Task-local storage for current DPI scaling ref during rendering
const CURRENT_DPI_SCALING = Ref{Union{Ref{DPIScaling},Nothing}}(nothing)

"""
    set_current_dpi_scaling!(dpi_scaling_ref::Ref{DPIScaling})

Set the current DPI scaling ref for this rendering context.
This is used internally by the rendering system.
"""
function set_current_dpi_scaling!(dpi_scaling_ref::Ref{DPIScaling})
    CURRENT_DPI_SCALING[] = dpi_scaling_ref
end

"""
    get_current_dpi_scaling()::Ref{DPIScaling}

Get the current DPI scaling ref for this rendering context.
Throws an error if no DPI scaling is set (which shouldn't happen during normal rendering).
"""
function get_current_dpi_scaling()::Ref{DPIScaling}
    current = CURRENT_DPI_SCALING[]
    if current === nothing
        error("No DPI scaling ref is set. This function should only be called during UI rendering.")
    end
    return current
end

"""
    create_dpi_scaling_ref()::Ref{DPIScaling}

Create a new DPI scaling reference with default 1x scaling.
This must be passed to Fugl.run() for proper scaling support.

# Example
```julia
dpi_ref = create_dpi_scaling_ref()
Fugl.run(MyApp, dpi_scaling=dpi_ref)
```
"""
function create_dpi_scaling_ref()::Ref{DPIScaling}
    return Ref(DPIScaling(0.0f0, 0.0f0, 0.0f0, 0.0f0, 1.0f0))  # Default 1x scale (1 point = 1 pixel)
end

"""    update_dpi_scaling!(dpi_scaling_ref::Ref{DPIScaling}, window_width::Integer, window_height::Integer, fb_width::Integer, fb_height::Integer)

Update the DPI scaling with current window and framebuffer sizes.
No automatic DPI detection - only tracks window dimensions.
"""
function update_dpi_scaling!(dpi_scaling_ref::Ref{DPIScaling}, window_width::Integer, window_height::Integer, fb_width::Integer, fb_height::Integer)
    dpi_scaling_ref[].logical_width = Float32(window_width)
    dpi_scaling_ref[].logical_height = Float32(window_height)
    dpi_scaling_ref[].pixel_width = Float32(fb_width)
    dpi_scaling_ref[].pixel_height = Float32(fb_height)
end

"""    fugl_to_pixels(dpi_scaling_ref::Ref{DPIScaling}, fugl_coord::Float32)::Float32

Convert a Fugl logical coordinate to screen pixels using manual scaling.
1 point = manual_scale pixels.
"""
@inline fugl_to_pixels(dpi_scaling_ref::Ref{DPIScaling}, fugl_coord::Float32)::Float32 = fugl_coord * dpi_scaling_ref[].manual_scale
@inline fugl_to_pixels_x(dpi_scaling_ref::Ref{DPIScaling}, fugl_x::Float32)::Float32 = fugl_x * dpi_scaling_ref[].manual_scale

"""    fugl_to_pixels_y(dpi_scaling_ref::Ref{DPIScaling}, fugl_y::Float32)::Float32

Convert a Fugl logical Y coordinate to screen pixels using manual scaling.
"""
@inline fugl_to_pixels_y(dpi_scaling_ref::Ref{DPIScaling}, fugl_y::Float32)::Float32 = fugl_y * dpi_scaling_ref[].manual_scale


"""    pixels_to_fugl(dpi_scaling_ref::Ref{DPIScaling}, pixel_coord::Float32)::Float32

Convert screen pixels to Fugl logical coordinates using manual scaling.
"""
@inline pixels_to_fugl(dpi_scaling_ref::Ref{DPIScaling}, pixel_coord::Float32)::Float32 = pixel_coord / dpi_scaling_ref[].manual_scale


"""    pixels_to_fugl_x(dpi_scaling_ref::Ref{DPIScaling}, pixel_x::Float32)::Float32

Convert screen pixels to Fugl logical X coordinate using manual scaling.
"""
@inline pixels_to_fugl_x(dpi_scaling_ref::Ref{DPIScaling}, pixel_x::Float32)::Float32 = pixel_x / dpi_scaling_ref[].manual_scale


"""    pixels_to_fugl_y(dpi_scaling_ref::Ref{DPIScaling}, pixel_y::Float32)::Float32

Convert screen pixels to Fugl logical Y coordinate using manual scaling.
"""
@inline pixels_to_fugl_y(dpi_scaling_ref::Ref{DPIScaling}, pixel_y::Float32)::Float32 = pixel_y / dpi_scaling_ref[].manual_scale

"""    get_dpi_scale(dpi_scaling_ref::Ref{DPIScaling})::Tuple{Float32, Float32}

Get the current manual scaling factor as both X and Y scaling (they're the same).
"""
@inline get_dpi_scale(dpi_scaling_ref::Ref{DPIScaling})::Tuple{Float32,Float32} = (dpi_scaling_ref[].manual_scale, dpi_scaling_ref[].manual_scale)

"""    get_logical_size(dpi_scaling_ref::Ref{DPIScaling})::Tuple{Float32, Float32}

Get the current window size in logical coordinates (width, height).
This is what components should use for layout calculations.
"""
@inline get_logical_size(dpi_scaling_ref::Ref{DPIScaling})::Tuple{Float32,Float32} = (dpi_scaling_ref[].logical_width, dpi_scaling_ref[].logical_height)

"""    get_pixel_size(dpi_scaling_ref::Ref{DPIScaling})::Tuple{Float32, Float32}

Get the current framebuffer size in actual pixels (width, height).
This is used internally for OpenGL rendering.
"""
@inline get_pixel_size(dpi_scaling_ref::Ref{DPIScaling})::Tuple{Float32,Float32} = (dpi_scaling_ref[].pixel_width, dpi_scaling_ref[].pixel_height)

"""
    set_manual_scaling!(scale_factor::Float32)

Set the UI scaling factor (1x = 1 point = 1 pixel, 2x = 1 point = 2 pixels).
System DPI scaling is ignored for consistent 1:1 pixel mapping.
Supports fractional values for smooth scaling.

# Arguments
- `scale_factor`: UI scale multiplier (0.25 = quarter size, 0.5 = half size, 1.0 = normal size, 2.0 = twice as large, etc.)

# Example
```julia
# Half size: 1 point = 0.5 pixels
Fugl.set_manual_scaling!(0.5f0)

# Normal size: 1 point = 1 pixel
Fugl.set_manual_scaling!(1.0f0)

# Large UI: 1 point = 2 pixels  
Fugl.set_manual_scaling!(2.0f0)
```
"""
function set_manual_scaling!(dpi_scaling_ref::Ref{DPIScaling}, scale_factor::Float32)
    # Allow fractional scaling values for smooth scaling
    dpi_scaling_ref[].manual_scale = max(0.25f0, min(4.0f0, scale_factor))  # Clamp between 0.25x and 4x for reasonable bounds
end


"""    get_effective_scale(dpi_scaling_ref::Ref{DPIScaling})::Float32

Get the effective scaling factor being applied to the UI.
This is just the manual scaling factor (1.0 = 1 point = 1 pixel).
"""
function get_effective_scale(dpi_scaling_ref::Ref{DPIScaling})::Float32
    return dpi_scaling_ref[].manual_scale
end


"""    adjust_manual_scaling!(dpi_scaling_ref::Ref{DPIScaling}, delta::Float32)

Adjust the manual scaling by a delta amount. Positive values increase scale, negative decrease.
Clamped to reasonable bounds (0.25x to 4x with fractional values supported).
"""
function adjust_manual_scaling!(dpi_scaling_ref::Ref{DPIScaling}, delta::Float32)
    new_scale = dpi_scaling_ref[].manual_scale + delta
    # Allow fractional scaling values
    dpi_scaling_ref[].manual_scale = max(0.25f0, min(4.0f0, new_scale))
end

"""    get_manual_scaling(dpi_scaling_ref::Ref{DPIScaling})::Float32

Get the current manual scaling factor (1.0 = normal, 2.0 = twice as large, etc.)
"""
function get_manual_scaling(dpi_scaling_ref::Ref{DPIScaling})::Float32
    return dpi_scaling_ref[].manual_scale
end

"""    get_system_dpi_ratio(dpi_scaling_ref::Ref{DPIScaling})::Float32

Get the system's DPI ratio (pixels per point). On Retina displays this is typically 2.0.
"""
function get_system_dpi_ratio(dpi_scaling_ref::Ref{DPIScaling})::Float32
    if dpi_scaling_ref[].logical_width > 0
        return dpi_scaling_ref[].pixel_width / dpi_scaling_ref[].logical_width
    else
        return 1.0f0  # Default if no window size set yet
    end
end

"""    get_pixel_perfect_scale(dpi_scaling_ref::Ref{DPIScaling})::Float32

Get the scaling factor that achieves 1 point = 1 actual pixel when manual_scale=1.
This compensates for the system DPI ratio.
"""
function get_pixel_perfect_scale(dpi_scaling_ref::Ref{DPIScaling})::Float32
    system_dpi = get_system_dpi_ratio(dpi_scaling_ref)
    return dpi_scaling_ref[].manual_scale / system_dpi
end

# Convenience functions that use the current DPI scaling context
# These allow existing code to work without passing explicit refs

"""
    get_manual_scaling()::Float32

Get the current manual scaling factor using the current DPI scaling context.
"""
get_manual_scaling()::Float32 = get_manual_scaling(get_current_dpi_scaling())

"""
    get_system_dpi_ratio()::Float32

Get the system DPI ratio using the current DPI scaling context.
"""
get_system_dpi_ratio()::Float32 = get_system_dpi_ratio(get_current_dpi_scaling())

"""
    get_pixel_perfect_scale()::Float32

Get the pixel-perfect scaling factor using the current DPI scaling context.
"""
get_pixel_perfect_scale()::Float32 = get_pixel_perfect_scale(get_current_dpi_scaling())

"""
    get_effective_scale()::Float32

Get the effective scaling factor using the current DPI scaling context.
"""
get_effective_scale()::Float32 = get_effective_scale(get_current_dpi_scaling())

"""
    get_dpi_scale()::Tuple{Float32, Float32}

Get the current DPI scaling factors using the current DPI scaling context.
"""
get_dpi_scale()::Tuple{Float32,Float32} = get_dpi_scale(get_current_dpi_scaling())

"""
    adjust_manual_scaling!(delta::Float32)

Adjust manual scaling using the current DPI scaling context.
"""
adjust_manual_scaling!(delta::Float32) = adjust_manual_scaling!(get_current_dpi_scaling(), delta)

"""
    set_manual_scaling!(scale_factor::Float32)

Set manual scaling using the current DPI scaling context.
"""
set_manual_scaling!(scale_factor::Float32) = set_manual_scaling!(get_current_dpi_scaling(), scale_factor)