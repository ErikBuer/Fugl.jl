

# Line style enumeration  
@enum LineStyle begin
    SOLID = 0
    DASH = 1
    DOT = 2
    DASHDOT = 3
end

mutable struct PlotStyle
    background_color::Vec4{Float32}
    grid_color::Vec4{Float32}
    axis_color::Vec4{Float32}
    padding_px::Float32
    show_grid::Bool
    show_axes::Bool
    show_legend::Bool
end

function PlotStyle(;
    background_color=Vec4{Float32}(1.0f0, 1.0f0, 1.0f0, 1.0f0),  # White background
    grid_color=Vec4{Float32}(0.9f0, 0.9f0, 0.9f0, 1.0f0),  # Light gray grid
    axis_color=Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 1.0f0),  # Black axes
    padding_px=40.0f0,  # More padding to accommodate axis labels outside plot area
    show_grid=true,
    show_axes=true,
    show_legend=false
)
    return PlotStyle(background_color, grid_color, axis_color, padding_px, show_grid, show_axes, show_legend)
end