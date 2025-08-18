using Fugl
using Fugl: Text

function image_plot_demo()
    # Create test image data
    size_x, size_y = 50, 50

    # Create a 2D Gaussian pattern
    data = Matrix{Float32}(undef, size_y, size_x)
    center_x, center_y = size_x / 2, size_y / 2

    plot1_state = Ref(PlotState())

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
        ImagePlotElement(
        data;
        x_range=(0.0, 10.0),
        y_range=(0.0, 10.0),
        colormap=:viridis,
        label="Viridis Map"
    )
    ]

    function MyApp()
        IntrinsicColumn([
                IntrinsicHeight(Container(Text("Image Plot Demo - 2D Gaussian + Waves"))),
                Container(
                    Plot(
                        elements,
                        PlotStyle(
                            show_grid=true,
                            show_axes=true,
                            show_legend=true,
                            padding_px=50.0f0
                        ),
                        plot1_state[],
                        (new_state) -> plot1_state[] = new_state
                    )
                ),
            ], padding=0.0, spacing=0.0)
    end

    Fugl.run(MyApp, title="Image Plot Demo", window_width_px=800, window_height_px=600, fps_overlay=true)
end

image_plot_demo()
