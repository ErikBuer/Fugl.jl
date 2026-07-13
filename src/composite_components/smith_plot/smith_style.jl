struct SmithStyle
    background_color::Vec4f
    grid_color::Vec4f
    axis_color::Vec4f
    outer_circle_color::Vec4f
    trace_color::Vec4f
    label_color::Vec4f
    label_size_points::Int
    marker_fill_color::Vec4f
    marker_border_color::Vec4f
    grid_width::Float32
    axis_width::Float32
    outer_circle_width::Float32
    trace_width::Float32
    marker_size::Float32
    marker_border_width::Float32
    show_labels::Bool
    show_markers::Bool
    show_admittance_grid::Bool
    padding::Float32
    anti_aliasing_width::Float32
end

function SmithStyle(;
    background_color::Vec4f=Vec4f(1.0, 1.0, 1.0, 1.0),
    grid_color::Vec4f=Vec4f(0.75, 0.75, 0.75, 1.0),
    axis_color::Vec4f=Vec4f(0.45, 0.45, 0.45, 1.0),
    outer_circle_color::Vec4f=Vec4f(0.2, 0.2, 0.2, 1.0),
    trace_color::Vec4f=Vec4f(0.05, 0.45, 0.85, 1.0),
    label_color::Vec4f=Vec4f(0.2, 0.2, 0.2, 1.0),
    label_size_points::Int=11,
    marker_fill_color::Vec4f=Vec4f(0.05, 0.45, 0.85, 1.0),
    marker_border_color::Vec4f=Vec4f(0.05, 0.2, 0.4, 1.0),
    grid_width::Float32=1.0f0,
    axis_width::Float32=1.2f0,
    outer_circle_width::Float32=2.0f0,
    trace_width::Float32=2.2f0,
    marker_size::Float32=5.0f0,
    marker_border_width::Float32=1.0f0,
    show_labels::Bool=true,
    show_markers::Bool=true,
    show_admittance_grid::Bool=true,
    padding::Float32=40.0f0,
    anti_aliasing_width::Float32=1.0f0
)::SmithStyle
    return SmithStyle(
        background_color,
        grid_color,
        axis_color,
        outer_circle_color,
        trace_color,
        label_color,
        label_size_points,
        marker_fill_color,
        marker_border_color,
        grid_width,
        axis_width,
        outer_circle_width,
        trace_width,
        marker_size,
        marker_border_width,
        show_labels,
        show_markers,
        show_admittance_grid,
        padding,
        anti_aliasing_width
    )
end

function SmithStyle(base::SmithStyle;
    background_color=base.background_color,
    grid_color=base.grid_color,
    axis_color=base.axis_color,
    outer_circle_color=base.outer_circle_color,
    trace_color=base.trace_color,
    label_color=base.label_color,
    label_size_points=base.label_size_points,
    marker_fill_color=base.marker_fill_color,
    marker_border_color=base.marker_border_color,
    grid_width=base.grid_width,
    axis_width=base.axis_width,
    outer_circle_width=base.outer_circle_width,
    trace_width=base.trace_width,
    marker_size=base.marker_size,
    marker_border_width=base.marker_border_width,
    show_labels=base.show_labels,
    show_markers=base.show_markers,
    show_admittance_grid=base.show_admittance_grid,
    padding=base.padding,
    anti_aliasing_width=base.anti_aliasing_width
)::SmithStyle
    return SmithStyle(
        background_color,
        grid_color,
        axis_color,
        outer_circle_color,
        trace_color,
        label_color,
        label_size_points,
        marker_fill_color,
        marker_border_color,
        grid_width,
        axis_width,
        outer_circle_width,
        trace_width,
        marker_size,
        marker_border_width,
        show_labels,
        show_markers,
        show_admittance_grid,
        padding,
        anti_aliasing_width
    )
end
