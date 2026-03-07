# Polar Scatter Plot

``` @example PolarScatterBasic
using Fugl
using Fugl: Text

# Create scatter points at regular angular intervals
theta = range(0, 2π, length=16)
r = 0.6f0 .+ 0.3f0 .* rand(Float32, 16)

# Dark theme card style
dark_card_style = ContainerStyle(
    background_color=Vec4f(0.15, 0.15, 0.18, 1.0),
    border_color=Vec4f(0.25, 0.25, 0.30, 1.0),
    border_width=1.5f0,
    padding=12.0f0,
    corner_radius=6.0f0,
    anti_aliasing_width=1.0f0
)

dark_title_style = TextStyle(
    size_px=18,
    color=Vec4f(0.9, 0.9, 0.95, 1.0)
)

# Dark theme polar style
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
        "Polar Scatter Plot",
        PolarPlot(
            [
                PolarScatter(
                    Float32.(r),
                    Float32.(theta),
                    fill_color=Vec4f(0.9, 0.4, 0.4, 1.0),
                    border_color=Vec4f(0.9, 0.9, 0.95, 1.0),
                    marker_size=12.0f0,
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

screenshot(MyApp, "polarScatter.png", 800, 800);
nothing #hide
```

![Polar Scatter](polarScatter.png)

## Multiple Scatter Series Example

``` @example PolarScatterMulti
using Fugl
using Fugl: Text

# Create two sets of scatter points
theta1 = range(0, 2π, length=8)
r1 = fill(0.8f0, 8)

theta2 = range(π/8, 2π + π/8, length=8)
r2 = fill(0.5f0, 8)

# Dark theme card style
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

# Dark theme polar style
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
    theta_start=Float32(π / 2),
    theta_direction=:counterclockwise,
    num_angular_lines=8,
    angular_label_format=:degrees
)

function MyApp()
    Card(
        "Multiple Scatter Series",
        PolarPlot(
            [
                PolarScatter(
                    Float32.(r1),
                    Float32.(theta1),
                    fill_color=Vec4f(0.9, 0.4, 0.4, 1.0),
                    border_color=Vec4f(0.9, 0.9, 0.95, 1.0),
                    marker_size=14.0f0,
                    border_width=1.5f0
                ),
                PolarScatter(
                    Float32.(r2),
                    Float32.(theta2),
                    fill_color=Vec4f(0.4, 0.6, 0.9, 1.0),
                    border_color=Vec4f(0.9, 0.9, 0.95, 1.0),
                    marker_size=14.0f0,
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

screenshot(MyApp, "polarScatterMulti.png", 800, 800);
nothing #hide
```

![Polar Scatter Multi](polarScatterMulti.png)

## Combined Line and Scatter Example

``` @example PolarScatterCombined
using Fugl
using Fugl: Text

# Create continuous spiral curve
theta_line = range(0, 4π, length=300)
r_line = theta_line ./ (4π)

# Add scatter points at key locations
scatter_theta = range(0, 2π, length=8)
scatter_r = fill(0.8f0, 8)

# Dark theme card style
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

# Dark theme polar style
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
        "Polar Line + Scatter",
        PolarPlot(
            [
                PolarLine(
                    Float32.(r_line),
                    Float32.(theta_line),
                    color=Vec4f(0.4, 0.6, 0.9, 1.0),
                    width=2.0f0
                ),
                PolarScatter(
                    scatter_r,
                    Float32.(scatter_theta),
                    fill_color=Vec4f(0.9, 0.4, 0.4, 1.0),
                    border_color=Vec4f(0.9, 0.9, 0.95, 1.0),
                    marker_size=12.0f0,
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

screenshot(MyApp, "polarScatterCombined.png", 800, 800);
nothing #hide
```

![Polar Scatter Combined](polarScatterCombined.png)
