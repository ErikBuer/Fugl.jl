# Polar Stem Plot

Polar stem plots display data as radial lines extending from the origin (r=0) to each data point, with markers at the endpoints. They're useful for visualizing discrete samples in polar coordinates.

## Basic Example

``` @example PolarStemBasic
using Fugl
using Fugl: Text

# Create data points at regular angular intervals
theta = range(0, 2π, length=12)
r = 0.5f0 .+ 0.3f0 .* sin.(3.0f0 .* theta)

# Dark theme styling
dark_card_style = ContainerStyle(
    background_color=Vec4f(0.15, 0.15, 0.18, 1.0),
    border_color=Vec4f(0.25, 0.25, 0.30, 1.0),
    border_width=1.5f0,
    padding=12.0f0,
    corner_radius=6.0f0
)

dark_title_style = TextStyle(
    size_px=18,
    color=Vec4f(0.9, 0.9, 0.95, 1.0)
)

polar_style = PolarStyle(
    background_color=Vec4f(0.08, 0.10, 0.14, 1.0),
    show_radial_grid=true,
    show_angular_grid=true,
    radial_grid_color=Vec4f(0.25, 0.25, 0.30, 1.0),
    angular_grid_color=Vec4f(0.25, 0.25, 0.30, 1.0),
    show_outer_circle=true,
    outer_circle_color=Vec4f(0.9, 0.9, 0.95, 1.0),
    outer_circle_width=2.0f0,
    label_color=Vec4f(0.9, 0.9, 0.95, 1.0)
)

polar_state = PolarState(
    theta_start=0.0f0,
    theta_direction=:counterclockwise,
    num_angular_lines=12,
    angular_label_format=:degrees
)

function MyApp()
    Card(
        "Basic Polar Stem Plot",
        PolarPlot(
            [
                PolarStem(
                    Float32.(r),
                    Float32.(theta),
                    line_color=Vec4f(0.4, 0.6, 0.9, 1.0),
                    line_width=2.0f0,
                    fill_color=Vec4f(0.4, 0.6, 0.9, 1.0),
                    border_color=Vec4f(0.9, 0.9, 0.95, 1.0),
                    marker_size=10.0f0,
                    border_width=1.5f0
                )
            ],
            polar_style,
            polar_state
        ),
        style=dark_card_style,
        title_style=dark_title_style
    )
end

screenshot(MyApp, "polarStemBasic.png", 800, 800);
nothing #hide
```

![Basic Polar Stem](polarStemBasic.png)

## Multiple Data Series

``` @example PolarStemMultiple
using Fugl
using Fugl: Text

# Create two data series at different frequencies
theta = range(0, 2π, length=16)
r1 = 0.7f0 .+ 0.2f0 .* cos.(2.0f0 .* theta)
r2 = 0.4f0 .+ 0.15f0 .* cos.(4.0f0 .* theta)

# Dark theme styling
dark_card_style = ContainerStyle(
    background_color=Vec4f(0.15, 0.15, 0.18, 1.0),
    border_color=Vec4f(0.25, 0.25, 0.30, 1.0),
    border_width=1.5f0,
    padding=12.0f0,
    corner_radius=6.0f0
)

dark_title_style = TextStyle(
    size_px=18,
    color=Vec4f(0.9, 0.9, 0.95, 1.0)
)

polar_style = PolarStyle(
    background_color=Vec4f(0.08, 0.10, 0.14, 1.0),
    show_radial_grid=true,
    show_angular_grid=true,
    radial_grid_color=Vec4f(0.25, 0.25, 0.30, 1.0),
    angular_grid_color=Vec4f(0.25, 0.25, 0.30, 1.0),
    show_outer_circle=true,
    outer_circle_color=Vec4f(0.9, 0.9, 0.95, 1.0),
    outer_circle_width=2.0f0,
    label_color=Vec4f(0.9, 0.9, 0.95, 1.0)
)

polar_state = PolarState(
    theta_start=Float32(π/2),  # 0° points up
    theta_direction=:counterclockwise,
    num_angular_lines=8,
    angular_label_format=:degrees
)

function MyApp()
    Card(
        "Multiple Stem Series",
        PolarPlot(
            [
                PolarStem(
                    Float32.(r1),
                    Float32.(theta),
                    line_color=Vec4f(0.9, 0.4, 0.4, 1.0),  # Red
                    line_width=2.0f0,
                    fill_color=Vec4f(0.9, 0.4, 0.4, 1.0),
                    border_color=Vec4f(0.9, 0.9, 0.95, 1.0),
                    marker_size=9.0f0,
                    border_width=1.5f0
                ),
                PolarStem(
                    Float32.(r2),
                    Float32.(theta),
                    line_color=Vec4f(0.4, 0.9, 0.4, 1.0),  # Green
                    line_width=2.0f0,
                    fill_color=Vec4f(0.4, 0.9, 0.4, 1.0),
                    border_color=Vec4f(0.9, 0.9, 0.95, 1.0),
                    marker_size=9.0f0,
                    border_width=1.5f0
                )
            ],
            polar_style,
            polar_state
        ),
        style=dark_card_style,
        title_style=dark_title_style
    )
end

screenshot(MyApp, "polarStemMultiple.png", 800, 800);
nothing #hide
```

![Multiple Stem Series](polarStemMultiple.png)

## Combined with Other Elements

Stem plots can be combined with line and scatter plots for comprehensive data visualization:

``` @example PolarStemCombined
using Fugl
using Fugl: Text

# Continuous curve data
theta_line = range(0, 2π, length=200)
r_line = 0.6f0 .+ 0.3f0 .* cos.(3.0f0 .* theta_line)

# Sampled data
theta_stem = range(0, 2π, length=12)
r_stem = 0.6f0 .+ 0.3f0 .* cos.(3.0f0 .* theta_stem)

# Dark theme styling
dark_card_style = ContainerStyle(
    background_color=Vec4f(0.15, 0.15, 0.18, 1.0),
    border_color=Vec4f(0.25, 0.25, 0.30, 1.0),
    border_width=1.5f0,
    padding=12.0f0,
    corner_radius=6.0f0
)

dark_title_style = TextStyle(
    size_px=18,
    color=Vec4f(0.9, 0.9, 0.95, 1.0)
)

polar_style = PolarStyle(
    background_color=Vec4f(0.08, 0.10, 0.14, 1.0),
    show_radial_grid=true,
    show_angular_grid=true,
    radial_grid_color=Vec4f(0.25, 0.25, 0.30, 1.0),
    angular_grid_color=Vec4f(0.25, 0.25, 0.30, 1.0),
    show_outer_circle=true,
    outer_circle_color=Vec4f(0.9, 0.9, 0.95, 1.0),
    outer_circle_width=2.0f0,
    label_color=Vec4f(0.9, 0.9, 0.95, 1.0)
)

polar_state = PolarState(
    theta_start=0.0f0,
    theta_direction=:counterclockwise,
    num_angular_lines=12,
    angular_label_format=:degrees
)

function MyApp()
    Card(
        "Stem + Continuous Curve",
        PolarPlot(
            [
                # Continuous curve (underlying function)
                PolarLine(
                    Float32.(r_line),
                    Float32.(theta_line),
                    color=Vec4f(0.4, 0.4, 0.4, 0.5),  # Semi-transparent gray
                    width=1.5f0
                ),
                # Discrete samples
                PolarStem(
                    Float32.(r_stem),
                    Float32.(theta_stem),
                    line_color=Vec4f(0.4, 0.6, 0.9, 1.0),
                    line_width=2.0f0,
                    fill_color=Vec4f(0.4, 0.6, 0.9, 1.0),
                    border_color=Vec4f(0.9, 0.9, 0.95, 1.0),
                    marker_size=10.0f0,
                    border_width=1.5f0
                )
            ],
            polar_style,
            polar_state
        ),
        style=dark_card_style,
        title_style=dark_title_style
    )
end

screenshot(MyApp, "polarStemCombined.png", 800, 800);
nothing #hide
```

![Combined Plot](polarStemCombined.png)

## Stem Behavior with Zoom

Stem lines always originate from r=0 in the data coordinate system. When zooming:
- If r=0 is visible in the plot, stems extend from the center
- If the plot is zoomed to r_min > 0, stems start from r=0 (which will appear partway out from the center)
- If the plot shows negative values (r_min < 0), stems still start at r=0 (not at the plot boundary)

This ensures stems always represent the true magnitude from zero, regardless of zoom level.
