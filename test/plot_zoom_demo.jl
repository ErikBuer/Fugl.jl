using Fugl
using Fugl: Text, TextButton

function plot_zoom_demo()
    # Create plot data
    time_data = collect(0.0:0.1:10.0)
    y_data = sin.(time_data)

    # Create plot elements
    elements = AbstractPlotElement[
        LinePlotElement(
        y_data;
        x_data=time_data,
        color=Vec4{Float32}(0.0, 0.8, 0.2, 1.0),  # Green
        width=3.0f0,
        line_style=SOLID,
        label="Sine Wave"
    )
    ]

    # Create plot state for zoom control
    plot_state = Ref(PlotState())

    # Define plot style (visual appearance only)
    plot_style = PlotStyle(
        show_grid=true,
        show_axes=true,
        show_legend=true
    )

    function MyApp()
        IntrinsicColumn([
                IntrinsicHeight(Container(Text("Plot Demo"))),

                # Plot with user-managed state - much simpler!
                Container(
                    Plot(
                        elements,               # Elements are passed directly
                        plot_style,             # Style for visual appearance
                        plot_state[],          # State only contains bounds and zoom
                        (new_state) -> plot_state[] = new_state
                    )
                ),

                # Simple reset button
                IntrinsicHeight(Container(
                    TextButton(
                        "Reset View";
                        on_click=() -> begin
                            plot_state[] = PlotState()  # Reset to auto-scale
                        end
                    )
                ))
            ], padding=0.0, spacing=0.0)
    end

    Fugl.run(MyApp, title="Plot Zoom Demo", window_width_px=800, window_height_px=600, fps_overlay=true)
end

plot_zoom_demo()
