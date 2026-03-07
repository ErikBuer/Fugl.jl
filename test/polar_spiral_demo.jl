using Fugl
using Fugl: Text

# Create polar plot with theta_start pointing up (like many polar plot systems)
# Spiral pattern
theta = range(0, 4π, length=300)
r = theta ./ (4π)  # Spiral from 0 to 1

# Scatter points
scatter_theta = range(0, 2π, length=8)
scatter_r = fill(0.8f0, 8)

polar_style = PolarStyle(
    background_color=Vec4f(0.98, 0.98, 1.0, 1.0),
    show_radial_grid=true,
    show_angular_grid=true,
    radial_grid_color=Vec4f(0.7, 0.8, 0.9, 1.0),
    angular_grid_color=Vec4f(0.7, 0.8, 0.9, 1.0)
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
    Column(
        Card(
            "Polar Plot - Spiral (0° points up):",
            PolarPlot(
                [
                    PolarLine(
                        Float32.(r),
                        Float32.(theta),
                        color=Vec4f(0.2, 0.4, 0.8, 1.0),
                        width=2.0f0
                    ),
                    PolarScatter(
                        scatter_r,
                        Float32.(scatter_theta),
                        fill_color=Vec4f(0.9, 0.3, 0.2, 1.0),
                        border_color=Vec4f(0.1, 0.1, 0.1, 1.0),
                        marker_size=10.0f0,
                        border_width=1.5f0
                    )
                ],
                polar_style,
                polar_state
            ),
            style=ContainerStyle(
                background_color=Vec4f(0.95, 0.95, 0.95, 1.0),
                padding=10.0f0
            ),
            title_style=TextStyle(size_px=18, color=Vec4f(0.2, 0.2, 0.2, 1.0))
        ),
        Fugl.Text("θ starts at up/north (90°) and rotates counterclockwise",
            style=TextStyle(size_px=14)))
end
Fugl.run(MyApp,
    title="Polar Plot with Custom Orientation",
    window_width_px=800,
    window_height_px=800,
    fps_overlay=true
)
