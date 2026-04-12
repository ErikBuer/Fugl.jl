"""
VerticalColorbar represents a vertical colorbar plot element.
Size is controlled by FixedWidth layout component.
"""
struct VerticalColorbar <: AbstractPlotElement
    colormap::Symbol  # :viridis, :plasma, :hot, :grayscale, etc.
    value_range::Tuple{Float32,Float32}  # Min and max values for the colorbar
    label::String     # Optional label for the colorbar
    gradient_pixels::Int32 # Number of pixels in the gradient direction for smooth rendering
    muted::Bool
    hovered::Bool
end

"""
HorizontalColorbar represents a horizontal colorbar plot element.
Size is controlled by FixedHeight layout component.
"""
struct HorizontalColorbar <: AbstractPlotElement
    colormap::Symbol  # :viridis, :plasma, :hot, :grayscale, etc.
    value_range::Tuple{Float32,Float32}  # Min and max values for the colorbar
    label::String     # Optional label for the colorbar
    gradient_pixels::Int32 # Number of pixels in the gradient direction for smooth rendering
    muted::Bool
    hovered::Bool
end

# Constructors for VerticalColorbar
function VerticalColorbar(
    colormap::Symbol,
    value_range::Tuple{Real,Real};
    label::String="",
    gradient_pixels::Int=240,
    muted::Bool=false,
    hovered::Bool=false
)
    value_range_f32 = (Float32(value_range[1]), Float32(value_range[2]))
    return VerticalColorbar(colormap, value_range_f32, label, Int32(gradient_pixels), muted, hovered)
end

# Convenience constructor to extract from heatmap
function VerticalColorbar(
    heatmap::HeatmapElement;
    label::String="",
    gradient_pixels::Int=240,
    muted::Bool=false,
    hovered::Bool=false
)
    return VerticalColorbar(
        heatmap.colormap,
        heatmap.value_range,
        label=label,
        gradient_pixels=gradient_pixels,
        muted=muted,
        hovered=hovered
    )
end

"""
Create a new VerticalColorbar from an existing colorbar with keyword-based modifications.
"""
function VerticalColorbar(elem::VerticalColorbar;
    colormap=elem.colormap,
    value_range=elem.value_range,
    label=elem.label,
    gradient_pixels=elem.gradient_pixels,
    muted=elem.muted,
    hovered=elem.hovered
)
    return VerticalColorbar(colormap, value_range, label, gradient_pixels, muted, hovered)
end

"""
Toggle the muted state of a VerticalColorbar.
"""
toggle_mute(elem::VerticalColorbar) = VerticalColorbar(elem; muted=!elem.muted)

"""
Toggle the hovered state of a VerticalColorbar.
"""
toggle_hover(elem::VerticalColorbar) = VerticalColorbar(elem; hovered=!elem.hovered)

# Constructors for HorizontalColorbar
function HorizontalColorbar(
    colormap::Symbol,
    value_range::Tuple{Real,Real};
    label::String="",
    gradient_pixels::Int=240,
    muted::Bool=false,
    hovered::Bool=false
)
    value_range_f32 = (Float32(value_range[1]), Float32(value_range[2]))
    return HorizontalColorbar(colormap, value_range_f32, label, Int32(gradient_pixels), muted, hovered)
end

# Convenience constructor to extract from heatmap
function HorizontalColorbar(
    heatmap::HeatmapElement;
    label::String="",
    gradient_pixels::Int=240,
    muted::Bool=false,
    hovered::Bool=false
)
    return HorizontalColorbar(
        heatmap.colormap,
        heatmap.value_range,
        label=label,
        gradient_pixels=gradient_pixels,
        muted=muted,
        hovered=hovered
    )
end

"""
Create a new HorizontalColorbar from an existing colorbar with keyword-based modifications.
"""
function HorizontalColorbar(elem::HorizontalColorbar;
    colormap=elem.colormap,
    value_range=elem.value_range,
    label=elem.label,
    gradient_pixels=elem.gradient_pixels,
    muted=elem.muted,
    hovered=elem.hovered
)
    return HorizontalColorbar(colormap, value_range, label, gradient_pixels, muted, hovered)
end

"""
Toggle the muted state of a HorizontalColorbar.
"""
toggle_mute(elem::HorizontalColorbar) = HorizontalColorbar(elem; muted=!elem.muted)

"""
Toggle the hovered state of a HorizontalColorbar.
"""
toggle_hover(elem::HorizontalColorbar) = HorizontalColorbar(elem; hovered=!elem.hovered)
