using Fugl
using Fugl: Text

function simple_heatmap_test()
    # Create test data that clearly shows orientation
    # Bottom row (j=1) should be 1.0, top row (j=20) should be 0.0 if Y increases upward
    data = Float32[j / 20 for i in 1:20, j in 1:20]  # j increases from bottom to top

    plot_state = Ref(PlotState())

    # Create plot element
    elements = AbstractPlotElement[
        HeatmapElement(
        data;
        x_range=(0.0, 20.0),
        y_range=(0.0, 20.0),
        colormap=:viridis,
        nan_color=(1.0, 0.0, 1.0, 1.0),
        background_color=(0.0, 0.0, 0.0, 1.0)
    )
    ]

    function MyApp()
        IntrinsicColumn([
                IntrinsicHeight(Container(Text("Y-Gradient Test (dark=bottom, bright=top)"))),
                Container(
                    Plot(
                        elements,
                        PlotStyle(
                            show_grid=true,
                            show_legend=true,
                            padding_px=50.0f0
                        ),
                        plot_state[],
                        (new_state) -> plot_state[] = new_state
                    )
                ),
            ], padding=0.0, spacing=0.0)
    end

    Fugl.run(MyApp, title="Checkerboard Heatmap Test", window_width_px=600, window_height_px=500, fps_overlay=true)
end

simple_heatmap_test()
