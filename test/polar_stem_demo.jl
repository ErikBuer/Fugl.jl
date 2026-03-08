using Fugl
using Fugl: Text

# Create data points at regular angular intervals
theta = range(0, 2π, length=12)
r = 0.5f0 .+ 0.3f0 .* sin.(3.0f0 .* theta)

# Dark theme polar style
polar_style = PolarStyle(
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

# Configure state
polar_state = Ref(PolarState(
    theta_start=0.0f0,
    theta_direction=:counterclockwise,
    num_angular_lines=12,
    angular_label_format=:degrees
))

function MyApp()
    Column(
        Card(
            "Polar Stem Plot Demo (Ctrl+Scroll: r_max, Shift+Scroll: r_min, Mid-Drag: Pan)",
            PolarPlot(
                [PolarStem(
                    Float32.(r),
                    Float32.(theta),
                    stem_color=Vec4f(0.4, 0.6, 0.9, 1.0),  # Bright blue
                    stem_width=2.0f0,
                    marker_fill_color=Vec4f(0.4, 0.6, 0.9, 1.0),  # Bright blue (matching)
                    marker_border_color=Vec4f(0.9, 0.9, 0.95, 1.0),
                    marker_size=10.0f0,
                    marker_border_width=1.5f0
                )],
                polar_style,
                polar_state[],
                (new_state) -> polar_state[] = new_state
            ),
            style=ContainerStyle(
                background_color=Vec4f(0.15, 0.15, 0.18, 1.0),  # Dark card background
                border_color=Vec4f(0.25, 0.25, 0.30, 1.0),
                border_width=1.5f0,
                padding=10.0f0,
                corner_radius=6.0f0
            ),
            title_style=TextStyle(size_px=18, color=Vec4f(0.9, 0.9, 0.95, 1.0))  # Light title text
        ),
        Fugl.Text("Stem lines from origin to each data point", style=TextStyle(size_px=14, color=Vec4f(0.9, 0.9, 0.95, 1.0)))
    )
end

Fugl.run(MyApp,
    title="Polar Stem Plot Demo",
    window_width_px=800,
    window_height_px=800,
    fps_overlay=true
)
