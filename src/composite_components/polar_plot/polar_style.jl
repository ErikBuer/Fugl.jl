struct PolarStyle
    # Background
    background_color::Vec4f

    # Radial grid circles
    show_radial_grid::Bool
    radial_grid_color::Vec4f
    radial_grid_width::Float32

    # Angular grid lines (spokes)
    show_angular_grid::Bool
    angular_grid_color::Vec4f
    angular_grid_width::Float32

    # Outer circle (border)
    show_outer_circle::Bool
    outer_circle_color::Vec4f
    outer_circle_width::Float32

    # Axis labels
    show_radial_labels::Bool
    show_angular_labels::Bool
    label_color::Vec4f
    label_size_px::Int

    # Tick marks
    show_radial_ticks::Bool
    radial_tick_size::Float32
    radial_tick_width::Float32
    radial_tick_color::Vec4f
    show_angular_ticks::Bool
    angular_tick_size::Float32
    angular_tick_width::Float32
    angular_tick_color::Vec4f

    # Padding around the plot for labels
    padding::Float32
    # Anti-aliasing for smoother lines
    anti_aliasing_width::Float32
end


"""
Create PolarStyle with default values.
"""
function PolarStyle(;
    background_color::Vec4f=Vec4f(1.0, 1.0, 1.0, 1.0),
    show_radial_grid::Bool=true,
    radial_grid_color::Vec4f=Vec4f(0.8, 0.8, 0.8, 1.0),
    radial_grid_width::Float32=1.0f0,
    show_angular_grid::Bool=true,
    angular_grid_color::Vec4f=Vec4f(0.8, 0.8, 0.8, 1.0),
    angular_grid_width::Float32=1.0f0,
    show_outer_circle::Bool=true,
    outer_circle_color::Vec4f=Vec4f(0.2, 0.2, 0.2, 1.0),
    outer_circle_width::Float32=2.0f0,
    show_radial_labels::Bool=true,
    show_angular_labels::Bool=true,
    label_color::Vec4f=Vec4f(0.2, 0.2, 0.2, 1.0),
    label_size_px::Int=12,
    show_radial_ticks::Bool=true,
    radial_tick_size::Float32=6.0f0,
    radial_tick_width::Float32=1.0f0,
    radial_tick_color::Vec4f=Vec4f(0.2, 0.2, 0.2, 1.0),
    show_angular_ticks::Bool=true,
    angular_tick_size::Float32=6.0f0,
    angular_tick_width::Float32=1.0f0,
    angular_tick_color::Vec4f=Vec4f(0.2, 0.2, 0.2, 1.0),
    padding::Float32=40.0f0,
    anti_aliasing_width::Float32=1.0f0
)::PolarStyle
    return PolarStyle(
        background_color,
        show_radial_grid,
        radial_grid_color,
        radial_grid_width,
        show_angular_grid,
        angular_grid_color,
        angular_grid_width,
        show_outer_circle,
        outer_circle_color,
        outer_circle_width,
        show_radial_labels,
        show_angular_labels,
        label_color,
        label_size_px,
        show_radial_ticks,
        radial_tick_size,
        radial_tick_width,
        radial_tick_color,
        show_angular_ticks,
        angular_tick_size,
        angular_tick_width,
        angular_tick_color,
        padding,
        anti_aliasing_width
    )
end

"""
Create a new PolarStyle with modified fields.
"""
function PolarStyle(base::PolarStyle;
    background_color=base.background_color,
    show_radial_grid=base.show_radial_grid,
    radial_grid_color=base.radial_grid_color,
    radial_grid_width=base.radial_grid_width,
    show_angular_grid=base.show_angular_grid,
    angular_grid_color=base.angular_grid_color,
    angular_grid_width=base.angular_grid_width,
    show_outer_circle=base.show_outer_circle,
    outer_circle_color=base.outer_circle_color,
    outer_circle_width=base.outer_circle_width,
    show_radial_labels=base.show_radial_labels,
    show_angular_labels=base.show_angular_labels,
    label_color=base.label_color,
    label_size_px=base.label_size_px,
    show_radial_ticks=base.show_radial_ticks,
    radial_tick_size=base.radial_tick_size,
    radial_tick_width=base.radial_tick_width,
    radial_tick_color=base.radial_tick_color,
    show_angular_ticks=base.show_angular_ticks,
    angular_tick_size=base.angular_tick_size,
    angular_tick_width=base.angular_tick_width,
    angular_tick_color=base.angular_tick_color,
    padding=base.padding,
    anti_aliasing_width=base.anti_aliasing_width
)::PolarStyle
    return PolarStyle(
        background_color,
        show_radial_grid,
        radial_grid_color,
        radial_grid_width,
        show_angular_grid,
        angular_grid_color,
        angular_grid_width,
        show_outer_circle,
        outer_circle_color,
        outer_circle_width,
        show_radial_labels,
        show_angular_labels,
        label_color,
        label_size_px,
        show_radial_ticks,
        radial_tick_size,
        radial_tick_width,
        radial_tick_color,
        show_angular_ticks,
        angular_tick_size,
        angular_tick_width,
        angular_tick_color,
        padding,
        anti_aliasing_width
    )
end
