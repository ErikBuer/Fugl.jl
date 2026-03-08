using Fugl
using Fugl: Text, TextButton

# Create data with some negative and positive values
# This tests that stems correctly go to r=0, not to the plot center
theta = range(0, 2π, length=16)
r = -0.3f0 .+ 0.6f0 .* sin.(2.0f0 .* theta)  # Values from -0.9 to 0.3

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

# Start with auto-scaling which will include negative values
polar_state = Ref(PolarState(
    theta_start=0.0f0,
    theta_direction=:counterclockwise,
    num_angular_lines=12,
    angular_label_format=:degrees,
    r_min=-1.0f0,
    r_max=0.5f0,
    auto_scale_r=false
))

function MyApp()
    Column(
        Card(
            "Stem Plot with Negative Values (Ctrl+Scroll: r_max, Shift+Scroll: r_min, Mid-Drag: Pan)",
            PolarPlot(
                [
                    PolarStem(
                        Float32.(r),
                        Float32.(theta),
                        line_color=Vec4f(0.9, 0.4, 0.4, 1.0),
                        line_width=2.0f0,
                        fill_color=Vec4f(0.9, 0.4, 0.4, 1.0),
                        border_color=Vec4f(0.9, 0.9, 0.95, 1.0),
                        marker_size=10.0f0,
                        border_width=1.5f0
                    )
                ],
                polar_style,
                polar_state[],
                (new_state) -> polar_state[] = new_state
            ),
            style=ContainerStyle(
                background_color=Vec4f(0.15, 0.15, 0.18, 1.0),
                border_color=Vec4f(0.25, 0.25, 0.30, 1.0),
                border_width=1.5f0,
                padding=10.0f0,
                corner_radius=6.0f0
            ),
            title_style=TextStyle(size_px=18, color=Vec4f(0.9, 0.9, 0.95, 1.0))
        ),
        IntrinsicHeight(
            Row([
                    Fugl.Text("Data ranges from -0.9 to 0.3 | Stems originate at r=0",
                        style=TextStyle(size_px=14, color=Vec4f(0.9, 0.9, 0.95, 1.0))),
                    TextButton("Reset View",
                        on_click=() -> begin
                            polar_state[] = PolarState(polar_state[];
                                r_min=-1.0f0,
                                r_max=0.5f0,
                                auto_scale_r=false
                            )
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
                    ),
                    TextButton("Zoom to Positive",
                        on_click=() -> begin
                            polar_state[] = PolarState(polar_state[];
                                r_min=0.0f0,
                                r_max=0.5f0,
                                auto_scale_r=false
                            )
                        end,
                        container_style=ContainerStyle(
                            background_color=Vec4f(0.3, 0.4, 0.2, 1.0),
                            border_color=Vec4f(0.5, 0.6, 0.4, 1.0),
                            border_width=1.0f0,
                            padding=8.0f0,
                            corner_radius=4.0f0
                        ),
                        hover_style=ContainerStyle(
                            background_color=Vec4f(0.35, 0.45, 0.25, 1.0),
                            border_color=Vec4f(0.5, 0.6, 0.4, 1.0),
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
    title="Polar Stem with Negative Values",
    window_width_px=800,
    window_height_px=900,
    fps_overlay=true
)
