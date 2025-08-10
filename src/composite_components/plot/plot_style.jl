@enum PlotType begin
    LINE_PLOT = 0
    SCATTER_PLOT = 1
    STEM_PLOT = 2
    MATRIX_PLOT = 3
end

mutable struct PlotStyle
    background_color::Vec4{Float32}
    grid_color::Vec4{Float32}
    axis_color::Vec4{Float32}
    padding_px::Float32
    show_grid::Bool
    show_axes::Bool
    show_legend::Bool
    anti_aliasing_width::Float32  # Width of anti-aliasing transition in pixels (0.0 = disabled)
    # Initial view bounds (for reset functionality)
    initial_x_min::Union{Float32,Nothing}
    initial_x_max::Union{Float32,Nothing}
    initial_y_min::Union{Float32,Nothing}
    initial_y_max::Union{Float32,Nothing}
end

function PlotStyle(;
    background_color=Vec4{Float32}(1.0f0, 1.0f0, 1.0f0, 1.0f0),  # White background
    grid_color=Vec4{Float32}(0.9f0, 0.9f0, 0.9f0, 1.0f0),  # Light gray grid
    axis_color=Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 1.0f0),  # Black axes
    padding_px=40.0f0,  # More padding to accommodate axis labels outside plot area
    show_grid=true,
    show_axes=true,
    show_legend=false,
    anti_aliasing_width=2.0f0,  # Anti-aliasing transition width in pixels (0.0 = sharp edges)
    initial_x_min=nothing,  # Auto-scale if nothing
    initial_x_max=nothing,  # Auto-scale if nothing
    initial_y_min=nothing,  # Auto-scale if nothing
    initial_y_max=nothing   # Auto-scale if nothing
)
    return PlotStyle(background_color, grid_color, axis_color, padding_px, show_grid, show_axes, show_legend, anti_aliasing_width, initial_x_min, initial_x_max, initial_y_min, initial_y_max)
end