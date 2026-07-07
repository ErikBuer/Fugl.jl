# XAreaElement: vertical colored band between two x values (spans full visible Y range)
struct XAreaElement <: AbstractPlotElement
    x_min::Float32
    x_max::Float32
    color::Vec4{Float32}
    label::String
    muted::Bool
    hovered::Bool
end

"""
    XAreaElement(x_min, x_max; color, label, muted)

A decorative vertical area spanning the full Y range between two X values.
Useful for highlighting regions such as frequency bands, time intervals, etc.

The area is rendered behind other elements when placed first in the elements vector.

# Example
```julia
XAreaElement(2.4e9, 2.48e9;
    color=Vec4f(0.3, 0.7, 1.0, 0.15),
    label="2.4 GHz band"
)
```
"""
function XAreaElement(x_min::Real, x_max::Real;
    color::Vec4{Float32}=Vec4{Float32}(0.3f0, 0.6f0, 1.0f0, 0.18f0),
    label::String="",
    muted::Bool=false,
    hovered::Bool=false
)
    return XAreaElement(Float32(x_min), Float32(x_max), color, label, muted, hovered)
end

function XAreaElement(elem::XAreaElement;
    x_min=elem.x_min,
    x_max=elem.x_max,
    color=elem.color,
    label=elem.label,
    muted=elem.muted,
    hovered=elem.hovered
)
    return XAreaElement(x_min, x_max, color, label, muted, hovered)
end

toggle_mute(elem::XAreaElement) = XAreaElement(elem; muted=(!elem.muted))
toggle_hover(elem::XAreaElement) = XAreaElement(elem; hovered=(!elem.hovered))


# YAreaElement: horizontal colored band between two y values (spans full visible X range)
struct YAreaElement <: AbstractPlotElement
    y_min::Float32
    y_max::Float32
    color::Vec4{Float32}
    label::String
    muted::Bool
    hovered::Bool
end

"""
    YAreaElement(y_min, y_max; color, label, muted)

A decorative horizontal area spanning the full X range between two Y values.
Useful for highlighting value thresholds, tolerance zones, etc.

The area is rendered behind other elements when placed first in the elements vector.

# Example
```julia
YAreaElement(-0.5, 0.5;
    color=Vec4f(1.0, 0.8, 0.2, 0.15),
    label="Tolerance zone"
)
```
"""
function YAreaElement(y_min::Real, y_max::Real;
    color::Vec4{Float32}=Vec4{Float32}(1.0f0, 0.7f0, 0.2f0, 0.18f0),
    label::String="",
    muted::Bool=false,
    hovered::Bool=false
)
    return YAreaElement(Float32(y_min), Float32(y_max), color, label, muted, hovered)
end

function YAreaElement(elem::YAreaElement;
    y_min=elem.y_min,
    y_max=elem.y_max,
    color=elem.color,
    label=elem.label,
    muted=elem.muted,
    hovered=elem.hovered
)
    return YAreaElement(y_min, y_max, color, label, muted, hovered)
end

toggle_mute(elem::YAreaElement) = YAreaElement(elem; muted=(!elem.muted))
toggle_hover(elem::YAreaElement) = YAreaElement(elem; hovered=(!elem.hovered))


# Bands return NaN bounds to opt out of auto-scale calculations
function get_element_bounds(element::XAreaElement)::Tuple{Float32,Float32,Float32,Float32}
    return (NaN32, NaN32, NaN32, NaN32)
end

function get_element_bounds(element::YAreaElement)::Tuple{Float32,Float32,Float32,Float32}
    return (NaN32, NaN32, NaN32, NaN32)
end


# Drawing
function draw_plot_element_culled(element::XAreaElement, data_to_screen::Function, projection_matrix::Mat4{Float32}, style::PlotStyle, effective_bounds::Rectangle)
    x_lo = max(element.x_min, effective_bounds.x)
    x_hi = min(element.x_max, effective_bounds.x + effective_bounds.width)
    if x_lo >= x_hi
        return
    end

    color = element.muted ? Vec4f(element.color[1], element.color[2], element.color[3], element.color[4] * 0.4f0) : element.color

    sx_lo, sy_top = data_to_screen(x_lo, effective_bounds.y + effective_bounds.height)
    sx_hi, sy_bottom = data_to_screen(x_hi, effective_bounds.y)

    vertices = [
        Point2f(sx_lo, sy_top),
        Point2f(sx_lo, sy_bottom),
        Point2f(sx_hi, sy_bottom),
        Point2f(sx_hi, sy_top),
    ]
    draw_rectangle(vertices, color, projection_matrix)
end

function draw_plot_element_culled(element::YAreaElement, data_to_screen::Function, projection_matrix::Mat4{Float32}, style::PlotStyle, effective_bounds::Rectangle)
    y_lo = max(element.y_min, effective_bounds.y)
    y_hi = min(element.y_max, effective_bounds.y + effective_bounds.height)
    if y_lo >= y_hi
        return
    end

    color = element.muted ? Vec4f(element.color[1], element.color[2], element.color[3], element.color[4] * 0.4f0) : element.color

    sx_left, sy_top = data_to_screen(effective_bounds.x, y_hi)
    sx_right, sy_bottom = data_to_screen(effective_bounds.x + effective_bounds.width, y_lo)

    vertices = [
        Point2f(sx_left, sy_top),
        Point2f(sx_left, sy_bottom),
        Point2f(sx_right, sy_bottom),
        Point2f(sx_right, sy_top),
    ]
    draw_rectangle(vertices, color, projection_matrix)
end


# Legend samples: a small filled rectangle swatch
function render_legend_sample(element::XAreaElement, center_x::Float32, center_y::Float32, sample_width::Float32, sample_height::Float32, projection_matrix::Mat4{Float32})
    color = element.muted ? Vec4f(element.color[1], element.color[2], element.color[3], element.color[4] * 0.4f0) : element.color
    hw = sample_height * 0.35f0
    hx = sample_width * 0.30f0
    vertices = [
        Point2f(center_x - hx, center_y - hw),
        Point2f(center_x - hx, center_y + hw),
        Point2f(center_x + hx, center_y + hw),
        Point2f(center_x + hx, center_y - hw),
    ]
    draw_rectangle(vertices, color, projection_matrix)
end

function render_legend_sample(element::YAreaElement, center_x::Float32, center_y::Float32, sample_width::Float32, sample_height::Float32, projection_matrix::Mat4{Float32})
    color = element.muted ? Vec4f(element.color[1], element.color[2], element.color[3], element.color[4] * 0.4f0) : element.color
    hw = sample_height * 0.20f0
    hx = sample_width * 0.40f0
    vertices = [
        Point2f(center_x - hx, center_y - hw),
        Point2f(center_x - hx, center_y + hw),
        Point2f(center_x + hx, center_y + hw),
        Point2f(center_x + hx, center_y - hw),
    ]
    draw_rectangle(vertices, color, projection_matrix)
end
