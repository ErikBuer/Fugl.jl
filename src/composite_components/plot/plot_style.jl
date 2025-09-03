struct PlotStyle
    background_color::Vec4{Float32}
    grid_color::Vec4{Float32}
    grid_width::Float32
    axis_color::Vec4{Float32}
    padding::Float32
    show_grid::Bool
    # Axis line controls for each side
    show_left_axis::Bool     # Show left axis line
    show_right_axis::Bool    # Show right axis line  
    show_top_axis::Bool      # Show top axis line
    show_bottom_axis::Bool   # Show bottom axis line
    # Tick mark controls (small perpendicular lines)
    show_x_tick_marks::Bool  # Show x-axis tick marks
    show_y_tick_marks::Bool  # Show y-axis tick marks
    # Tick label controls (numbers/text)
    show_x_tick_labels::Bool # Show x-axis tick labels
    show_y_tick_labels::Bool # Show y-axis tick labels
    # Axis label controls (new)
    x_label::String          # Label for x-axis
    y_label::String          # Label for y-axis
    show_x_label::Bool       # Show x-axis label
    show_y_label::Bool       # Show y-axis label
    # Legacy combined controls (for backward compatibility)
    show_x_ticks::Bool       # Combined: show x-axis tick marks and labels
    show_y_ticks::Bool       # Combined: show y-axis tick marks and labels
    show_legend::Bool
    anti_aliasing_width::Float32  # Width of anti-aliasing transition in pixels (0.0 = disabled)
end

function PlotStyle(;
    background_color=Vec4{Float32}(1.0f0, 1.0f0, 1.0f0, 1.0f0),  # White background
    grid_color=Vec4{Float32}(0.5f0, 0.5f0, 0.5f0, 1.0f0),  # Light gray grid
    grid_width=1.5f0,
    axis_color=Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 1.0f0),  # Black axes
    padding=40.0f0,  # More padding to accommodate axis labels outside plot area
    show_grid=true,
    # Individual axis line controls
    show_left_axis=true,     # Show left axis line by default
    show_right_axis=false,   # Don't show right axis line by default
    show_top_axis=false,     # Don't show top axis line by default  
    show_bottom_axis=true,   # Show bottom axis line by default
    # Granular tick mark controls (new)
    show_x_tick_marks=nothing,  # Will default to show_x_ticks if not specified
    show_y_tick_marks=nothing,  # Will default to show_y_ticks if not specified
    show_x_tick_labels=nothing, # Will default to show_x_ticks if not specified
    show_y_tick_labels=nothing, # Will default to show_y_ticks if not specified
    # Axis label controls (new)
    x_label="",                # Label for x-axis
    y_label="",                # Label for y-axis
    show_x_label=false,         # Show x-axis label
    show_y_label=false,         # Show y-axis label
    # Combined tick controls (legacy)
    show_x_ticks=true,       # Show x-axis ticks by default
    show_y_ticks=true,       # Show y-axis ticks by default
    show_legend=false,
    anti_aliasing_width=2.0f0,  # Anti-aliasing transition width in pixels (0.0 = sharp edges)
)
    # Handle granular controls with fallback to combined controls
    final_show_x_tick_marks = show_x_tick_marks !== nothing ? show_x_tick_marks : show_x_ticks
    final_show_y_tick_marks = show_y_tick_marks !== nothing ? show_y_tick_marks : show_y_ticks
    final_show_x_tick_labels = show_x_tick_labels !== nothing ? show_x_tick_labels : show_x_ticks
    final_show_y_tick_labels = show_y_tick_labels !== nothing ? show_y_tick_labels : show_y_ticks

    return PlotStyle(background_color, grid_color, grid_width, axis_color, padding, show_grid,
        show_left_axis, show_right_axis, show_top_axis, show_bottom_axis,
        final_show_x_tick_marks, final_show_y_tick_marks,
        final_show_x_tick_labels, final_show_y_tick_labels,
        x_label, y_label, show_x_label, show_y_label,
        show_x_ticks, show_y_ticks, show_legend, anti_aliasing_width)
end