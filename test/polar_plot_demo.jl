using Fugl
using Fugl: Text

# Create a simple polar plot with a rose curve
# r = 1 + 0.5 * cos(5θ)
theta = range(0, 2π, length=200)
r = 1.0f0 .+ 0.5f0 .* cos.(5.0f0 .* theta)

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
    Column(
        Card(
            "Polar Plot - Rose Curve:",
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
            style=ContainerStyle(
                background_color=Vec4f(0.15, 0.15, 0.18, 1.0),  # Dark card background
                border_color=Vec4f(0.25, 0.25, 0.30, 1.0),
                border_width=1.5f0,
                padding=10.0f0,
                corner_radius=6.0f0
            ),
            title_style=TextStyle(size_px=18, color=Vec4f(0.9, 0.9, 0.95, 1.0))  # Light title text
        ),
        Fugl.Text("Rose curve: r = 1 + 0.5*cos(5θ)", style=TextStyle(size_px=14, color=Vec4f(0.9, 0.9, 0.95, 1.0)))
    )
end

Fugl.run(MyApp,
    title="Polar Plot Demo",
    window_width_px=800,
    window_height_px=800,
    fps_overlay=true
)
