"""
VerticalColorbar represents a vertical colorbar plot element.
Size is controlled by FixedWidth layout component.
"""
struct VerticalColorbar <: AbstractPlotElement
    colormap::Symbol  # :viridis, :plasma, :hot, :grayscale, etc.
    value_range::Tuple{Float32,Float32}  # Min and max values for the colorbar
    label::String     # Optional label for the colorbar
    gradient_pixels::Int32 # Number of pixels in the gradient direction for smooth rendering
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
end

# Constructors for VerticalColorbar
function VerticalColorbar(
    colormap::Symbol,
    value_range::Tuple{Real,Real};
    label::String="",
    gradient_pixels::Int=240
)
    value_range_f32 = (Float32(value_range[1]), Float32(value_range[2]))

    return VerticalColorbar(
        colormap,
        value_range_f32,
        label,
        Int32(gradient_pixels)
    )
end

# Convenience constructor to extract from heatmap
function VerticalColorbar(
    heatmap::HeatmapElement;
    label::String="",
    gradient_pixels::Int=240
)
    return VerticalColorbar(
        heatmap.colormap,
        heatmap.value_range,
        label=label,
        gradient_pixels=gradient_pixels
    )
end

# Constructors for HorizontalColorbar
function HorizontalColorbar(
    colormap::Symbol,
    value_range::Tuple{Real,Real};
    label::String="",
    gradient_pixels::Int=240
)
    value_range_f32 = (Float32(value_range[1]), Float32(value_range[2]))

    return HorizontalColorbar(
        colormap,
        value_range_f32,
        label,
        Int32(gradient_pixels)
    )
end

# Convenience constructor to extract from heatmap
function HorizontalColorbar(
    heatmap::HeatmapElement;
    label::String="",
    gradient_pixels::Int=240
)
    return HorizontalColorbar(
        heatmap.colormap,
        heatmap.value_range,
        label=label,
        gradient_pixels=gradient_pixels
    )
end
