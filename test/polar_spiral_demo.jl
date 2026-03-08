using Fugl
using Fugl: Text, TextButton

# Create polar plot with theta_start pointing up (like many polar plot systems)
# Spiral pattern
theta = range(0, 4π, length=300)
r = theta ./ (4π)  # Spiral from 0 to 1

# Scatter points
scatter_theta = range(0, 2π, length=8)
scatter_r = fill(0.8f0, 8)

# Stem plot data - periodic samples
stem_theta = range(0, 2π, length=12)
stem_r = 0.6f0 .+ 0.2f0 .* sin.(3.0f0 .* stem_theta)

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

# Configure state: 0° points up (π/2 radians)
# Use Ref for state management
polar_state = Ref(PolarState(
    theta_start=Float32(π / 2),        # 0 radians now points up/north
    theta_direction=:counterclockwise,
    num_radial_circles=5,
    num_angular_lines=8,
    angular_label_format=:degrees
))

function MyApp()
    Column(
        Card(
            "Polar Plot - Multiple Elements (Ctrl+Scroll: r_max, Shift+Scroll: r_min, Mid-Drag: Pan)",
            PolarPlot(
                [
                    PolarLine(
                        Float32.(r),
                        Float32.(theta),
                        color=Vec4f(0.4, 0.6, 0.9, 1.0),  # Bright blue for dark background
                        width=2.0f0
                    ),
                    PolarScatter(
                        scatter_r,
                        Float32.(scatter_theta),
                        fill_color=Vec4f(0.9, 0.4, 0.4, 1.0),  # Bright red for dark background
                        border_color=Vec4f(0.9, 0.9, 0.95, 1.0),  # Light border
                        marker_size=10.0f0,
                        border_width=1.5f0
                    ),
                    PolarStem(
                        Float32.(stem_r),
                        Float32.(stem_theta),
                        stem_color=Vec4f(0.4, 0.9, 0.4, 1.0),  # Bright green
                        stem_width=1.5f0,
                        marker_fill_color=Vec4f(0.4, 0.9, 0.4, 1.0),  # Bright green (matching)
                        marker_border_color=Vec4f(0.9, 0.9, 0.95, 1.0),
                        marker_size=8.0f0,
                        marker_border_width=1.5f0
                    )
                ],
                polar_style,
                polar_state[],
                (new_state) -> polar_state[] = new_state  # State change callback for zoom
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
        IntrinsicHeight(
            Row([
                    Fugl.Text("θ starts at up/north (90°) | Blue=spiral, Red=scatter, Green=stem",
                        style=TextStyle(size_px=14, color=Vec4f(0.9, 0.9, 0.95, 1.0))),
                    TextButton("Reset Zoom",
                        on_click=() -> begin
                            polar_state[] = PolarState(polar_state[]; r_min=0.0f0, r_max=1.0f0, auto_scale_r=false)
                        end,
                        container_style=ContainerStyle(
                            background_color=Vec4f(0.2, 0.3, 0.4, 1.0),
                            border_color=Vec4f(0.4, 0.5, 0.6, 1.0),
                            border_width=1.0f0,
                            padding=8.0f0,
                            corner_radius=4.0f0
                        ),
                        hover_style=ContainerStyle(
                            background_color=Vec4f(0.25, 0.35, 0.45, 1.0),
                            border_color=Vec4f(0.4, 0.5, 0.6, 1.0),
                            border_width=1.0f0,
                            padding=8.0f0,
                            corner_radius=4.0f0
                        ),
                        text_style=TextStyle(size_px=14, color=Vec4f(0.9, 0.9, 0.95, 1.0))
                    )
                ], spacing=10.0f0)
        )
    )
end

Fugl.run(MyApp,
    title="Polar Plot with Custom Orientation and Zoom",
    window_width_px=800,
    window_height_px=900,
    fps_overlay=true
)

