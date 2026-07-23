using Fugl
using Fugl: Text, TextButton, Row, TextStyle, ContainerStyle, InteractionState

function heatmap_plot_demo()
    # Create DPI scaling reference
    dpi_ref = create_dpi_scaling_ref()

    # Create test image data
    size_x, size_y = 50, 50

    # Create a 2D Gaussian pattern
    data = Matrix{Float32}(undef, size_y, size_x)
    center_x, center_y = size_x / 2, size_y / 2

    plot1_state = Ref(PlotState())

    # Button interaction states
    smaller_button_state = Ref(InteractionState())
    larger_button_state = Ref(InteractionState())
    reset_button_state = Ref(InteractionState())

    # Button styles
    normal_style = ContainerStyle(
        background_color=Vec4f(0.2, 0.4, 0.8, 1.0),
        border_color=Vec4f(0.1, 0.3, 0.7, 1.0),
        border_width=2.0f0,
        padding=0.0f0,
        corner_radius=4.0f0
    )

    hover_style = ContainerStyle(
        background_color=Vec4f(0.3, 0.5, 0.9, 1.0),
        border_color=Vec4f(0.2, 0.4, 0.8, 1.0),
        border_width=2.0f0,
        padding=0.0f0,
        corner_radius=4.0f0
    )

    pressed_style = ContainerStyle(
        background_color=Vec4f(0.1, 0.2, 0.6, 1.0),
        border_color=Vec4f(0.05, 0.15, 0.5, 1.0),
        border_width=2.0f0,
        padding=0.0f0,
        corner_radius=4.0f0
    )

    button_text_style = TextStyle(
        color=Vec4f(1.0, 1.0, 1.0, 1.0),
        size_points=12
    )

    for j in 1:size_y
        for i in 1:size_x
            # Distance from center
            dx = i - center_x
            dy = j - center_y
            distance_sq = dx^2 + dy^2

            # Gaussian pattern
            data[j, i] = exp(-distance_sq / (2 * (size_x / 6)^2))
        end
    end

    # Add some noise and secondary pattern
    for j in 1:size_y
        for i in 1:size_x
            # Add sinusoidal pattern
            wave = 0.3 * sin(i * 0.3) * cos(j * 0.3)
            data[j, i] += wave

            # Add some noise
            data[j, i] += 0.1 * (rand() - 0.5)
        end
    end

    # Create plot elements with different colormaps
    elements = AbstractPlotElement[
        HeatmapElement(
        data;
        x_range=(0.0, 10.0),
        y_range=(0.0, 10.0),
        colormap=:viridis,  # Use viridis instead of grayscale
        nan_color=(1.0, 0.0, 1.0, 1.0),  # Magenta for NaN values
        background_color=(0.2, 0.2, 0.2, 1.0),  # Dark gray background
        value_range=nothing  # Auto-detect from data
    )
    ]

    function MyApp()
        # Get current manual scaling value
        manual_scale = get_manual_scaling(dpi_ref)

        IntrinsicColumn([
                IntrinsicHeight(Container(Text("Heatmap Demo - 2D Gaussian + Waves"))),
                # DPI Scaling controls
                IntrinsicHeight(
                    Container(
                        Row([
                                TextButton("- Smaller",
                                    on_click=() -> adjust_manual_scaling!(-0.25f0),
                                    text_style=button_text_style,
                                    container_style=normal_style,
                                    hover_style=hover_style,
                                    pressed_style=pressed_style,
                                    interaction_state=smaller_button_state[],
                                    on_interaction_state_change=(new_state) -> smaller_button_state[] = new_state
                                ),
                                Container(
                                    Fugl.Text("Scale: $(round(manual_scale, digits=2))x", style=TextStyle(size_points=12)),
                                ),
                                TextButton("+ Larger",
                                    on_click=() -> adjust_manual_scaling!(0.25f0),
                                    text_style=button_text_style,
                                    container_style=normal_style,
                                    hover_style=hover_style,
                                    pressed_style=pressed_style,
                                    interaction_state=larger_button_state[],
                                    on_interaction_state_change=(new_state) -> larger_button_state[] = new_state
                                ),
                                TextButton("Reset 1x",
                                    on_click=() -> set_manual_scaling!(1.0f0),
                                    text_style=button_text_style,
                                    container_style=normal_style,
                                    hover_style=hover_style,
                                    pressed_style=pressed_style,
                                    interaction_state=reset_button_state[],
                                    on_interaction_state_change=(new_state) -> reset_button_state[] = new_state
                                )
                            ], spacing=10)
                    )
                ),
                Container(
                    Plot(
                        elements,
                        PlotStyle(
                            show_grid=true,
                            show_legend=true,
                            padding=0f0
                        ),
                        plot1_state[],
                        (new_state) -> plot1_state[] = new_state
                    )
                ),
            ], spacing=0.0)
    end

    Fugl.run(MyApp, title="Heatmap Demo", window_width_points=812, window_height_points=600, fps_overlay=true, dpi_scaling=dpi_ref)
end

heatmap_plot_demo()
