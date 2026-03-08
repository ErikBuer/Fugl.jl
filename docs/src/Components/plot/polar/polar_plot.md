# Polar Plot

``` @example PolarPlotExample
using Fugl
using Fugl: Text

# Create a rose curve: r = 1 + 0.5*cos(5θ)
theta = range(0, 2π, length=200)
r = 1.0f0 .+ 0.5f0 .* cos.(5.0f0 .* theta)

# Dark theme card style
dark_card_style = ContainerStyle(
    background_color=Vec4f(0.15, 0.15, 0.18, 1.0),  # Dark background
    border_color=Vec4f(0.25, 0.25, 0.30, 1.0),      # Subtle border
    border_width=1.5f0,
    padding=12.0f0,
    corner_radius=6.0f0,
    anti_aliasing_width=1.0f0
)

# Dark theme title style
dark_title_style = TextStyle(
    size_px=18,
    color=Vec4f(0.9, 0.9, 0.95, 1.0)  # Light text for titles
)

# Rose curve style - dark theme
rose_style = PolarStyle(
    background_color=Vec4f(0.08, 0.10, 0.14, 1.0),  # Very dark background
    show_radial_grid=true,
    show_angular_grid=true,
    radial_grid_color=Vec4f(0.25, 0.25, 0.30, 1.0),  # Subtle grid
    angular_grid_color=Vec4f(0.25, 0.25, 0.30, 1.0),
    show_outer_circle=true,
    outer_circle_color=Vec4f(0.9, 0.9, 0.95, 1.0),   # Light outer circle
    outer_circle_width=2.0f0,
    label_color=Vec4f(0.9, 0.9, 0.95, 1.0)           # Light labels
)

# Configure state: 0° points to the right (default)
polar_state = PolarState(
    theta_start=0.0f0,               # 0 radians = right/east
    theta_direction=:counterclockwise,
    num_angular_lines=12,            # Every 30 degrees
    angular_label_format=:degrees
)

function MyApp()
    Card(
        "Dark Theme Polar Plot",
        PolarPlot(
            [PolarLine(
                Float32.(r),
                Float32.(theta),
                color=Vec4f(0.9, 0.4, 0.4, 1.0),  # Bright red for dark background
                width=2.5f0
            )],
            rose_style,
            polar_state
        ),
        style=dark_card_style,
        title_style=dark_title_style
    )
end

screenshot(MyApp, "polarPlot.png", 800, 800);
nothing #hide
```

![Polar Plot](polarPlot.png)

## Custom Orientation Example

``` @example PolarOrientationExample
using Fugl
using Fugl: Text

# Create spiral pattern
theta = range(0, 4π, length=300)
r = theta ./ (4π)  # Spiral from 0 to 1

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

# Configure state: 0° points up (π/2 radians)
polar_state = PolarState(
    theta_start=Float32(π / 2),        # 0 radians now points up/north
    theta_direction=:counterclockwise,
    num_radial_circles=5,
    num_angular_lines=8,
    angular_label_format=:degrees
)

function MyApp()
    Card(
        "Polar Plot - Custom Orientation",
        PolarPlot(
            [
                PolarLine(
                    Float32.(r),
                    Float32.(theta),
                    color=Vec4f(0.4, 0.6, 0.9, 1.0),  # Bright blue
                    width=2.0f0
                )
            ],
            polar_style,
            polar_state
        ),
        style=dark_card_style,
        title_style=dark_title_style
    )
end

screenshot(MyApp, "polarOrientation.png", 800, 800);
nothing #hide
```

![Polar Orientation](polarOrientation.png)

## Multiple Data Series Example

``` @example PolarMultiSeriesExample
using Fugl
using Fugl: Text

# Create three different polar patterns
theta = range(0, 2π, length=150)

# Rose curve with 3 petals
r1 = 1.0f0 .+ 0.5f0 .* cos.(3.0f0 .* theta)

# Rose curve with 5 petals (smaller)
r2 = 0.7f0 .+ 0.3f0 .* cos.(5.0f0 .* theta)

# Circle
r3 = fill(0.5f0, length(theta))

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
        "Multiple Polar Data Series",
        PolarPlot(
            [
                PolarLine(
                    Float32.(r1),
                    Float32.(theta),
                    color=Vec4f(0.9, 0.4, 0.4, 1.0),  # Bright red
                    width=2.5f0
                ),
                PolarLine(
                    Float32.(r2),
                    Float32.(theta),
                    color=Vec4f(0.4, 0.6, 0.9, 1.0),  # Bright blue
                    width=2.5f0
                ),
                PolarLine(
                    Float32.(r3),
                    Float32.(theta),
                    color=Vec4f(0.4, 0.9, 0.4, 1.0),  # Bright green
                    width=2.0f0
                )
            ],
            polar_style,
            polar_state
        ),
        style=dark_card_style,
        title_style=dark_title_style
    )
end

screenshot(MyApp, "polarMultiSeries.png", 800, 800);
nothing #hide
```

![Polar Multi Series](polarMultiSeries.png)

## Stem Plot Example

``` @example PolarStemExample
using Fugl
using Fugl: Text

# Create data points at regular angular intervals
theta = range(0, 2π, length=12)
r = 0.5f0 .+ 0.3f0 .* sin.(3.0f0 .* theta)

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
        "Polar Stem Plot",
        PolarPlot(
            [
                PolarStem(
                    Float32.(r),
                    Float32.(theta),
                    line_color=Vec4f(0.4, 0.6, 0.9, 1.0),  # Bright blue
                    line_width=2.0f0,
                    fill_color=Vec4f(0.4, 0.6, 0.9, 1.0),  # Bright blue (matching)
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

screenshot(MyApp, "polarStem.png", 812, 812);
nothing #hide
```

![Polar Stem](polarStem.png)
