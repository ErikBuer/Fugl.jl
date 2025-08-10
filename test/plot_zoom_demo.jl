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

    # Create plot state for zoom control - now much simpler!
    plot_state = Ref(PlotState())

    # Define initial view bounds in the style (for reset functionality)
    plot_style = PlotStyle(
        show_grid=true,
        show_axes=true,
        show_legend=true,
        initial_x_min=2.0f0,      # Start zoomed in on x-axis
        initial_x_max=8.0f0,      # End zoomed in on x-axis  
        initial_y_min=-0.5f0,     # Start zoomed in on y-axis
        initial_y_max=0.5f0       # End zoomed in on y-axis
    )

    function MyApp()
        IntrinsicColumn([
                IntrinsicHeight(Container(Text("Plot Zoom Demo"))),

                # Plot with user-managed state - much simpler!
                Container(
                    Plot(
                        elements,               # Elements are passed directly
                        plot_style,
                        plot_state[],           # State only contains bounds and zoom
                        (new_state) -> plot_state[] = new_state
                    )
                ),

                # Controls for zoom
                IntrinsicHeight(
                    IntrinsicRow(
                        [
                            TextButton(
                                "Zoom In Y";
                                on_click=() -> begin
                                    current_state = plot_state[]
                                    # Create new state with tighter Y bounds
                                    y_min = something(current_state.current_y_min, plot_style.initial_y_min, -1.0f0)
                                    y_max = something(current_state.current_y_max, plot_style.initial_y_max, 1.0f0)
                                    y_center = (y_min + y_max) / 2
                                    y_range = (y_max - y_min) * 0.7f0  # Zoom in by 30%
                                    new_y_min = y_center - y_range / 2
                                    new_y_max = y_center + y_range / 2

                                    plot_state[] = PlotState(
                                        current_state.bounds,
                                        current_state.auto_scale,
                                        current_state.current_x_min,
                                        current_state.current_x_max,
                                        new_y_min,
                                        new_y_max
                                    )
                                end), TextButton(
                                "Zoom Out Y";
                                on_click=() -> begin
                                    current_state = plot_state[]
                                    # Create new state with wider Y bounds
                                    y_min = something(current_state.current_y_min, plot_style.initial_y_min, -1.0f0)
                                    y_max = something(current_state.current_y_max, plot_style.initial_y_max, 1.0f0)
                                    y_center = (y_min + y_max) / 2
                                    y_range = (y_max - y_min) * 1.4f0  # Zoom out by 40%
                                    new_y_min = y_center - y_range / 2
                                    new_y_max = y_center + y_range / 2

                                    plot_state[] = PlotState(
                                        current_state.bounds,
                                        current_state.auto_scale,
                                        current_state.current_x_min,
                                        current_state.current_x_max,
                                        new_y_min,
                                        new_y_max
                                    )
                                end), TextButton(
                                "Reset View";
                                on_click=() -> begin
                                    current_state = plot_state[]
                                    # Reset to initial view bounds from style
                                    plot_state[] = PlotState(
                                        current_state.bounds,
                                        current_state.auto_scale,
                                        plot_style.initial_x_min,
                                        plot_style.initial_x_max,
                                        plot_style.initial_y_min,
                                        plot_style.initial_y_max
                                    )
                                end
                            )
                        ], padding=0.0, spacing=0.0)
                ),            # Display current zoom bounds
                IntrinsicHeight(Container(Text("Current Bounds:"))),
                IntrinsicHeight(Container(Text("X: $(something(plot_state[].current_x_min, plot_style.initial_x_min, "auto")) to $(something(plot_state[].current_x_max, plot_style.initial_x_max, "auto"))"))),
            ], padding=0.0, spacing=0.0)
    end

    Fugl.run(MyApp, title="Plot Zoom Demo", window_width_px=800, window_height_px=600, fps_overlay=true)
end

plot_zoom_demo()
