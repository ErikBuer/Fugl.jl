using Fugl
using Fugl: Text

function main()
    # Simple streaming data simulation
    time_data = Ref(collect(0.0:0.1:10.0))
    y_data = Ref(sin.(time_data[]))

    # For real-time updates
    frame_count = Ref(0)

    # Plot states for interactive zoom/pan
    plot1_state = Ref(PlotState())
    plot2_state = Ref(PlotState())

    function MyApp()

        IntrinsicColumn([
                IntrinsicHeight(Container(Text("Real-time Line Plot Demo - Try Ctrl+Scroll to zoom!"))),

                # Line plot using LinePlotElement with different line styles
                Container(
                    Plot([
                            LinePlotElement(
                                y_data[];
                                x_data=time_data[],
                                color=Vec4{Float32}(0.0, 0.8, 0.2, 1.0),  # Green
                                width=4.0f0,
                                line_style=SOLID
                            ),
                            LinePlotElement(
                                cos.(time_data[]);
                                x_data=time_data[],
                                color=Vec4{Float32}(0.8, 0.2, 0.0, 1.0),  # Red
                                width=3.0f0,
                                line_style=DASH
                            )
                        ],
                        PlotStyle(show_grid=true, show_legend=true),
                        plot1_state[],  # Add state management
                        (new_state) -> plot1_state[] = new_state  # Add callback
                    )
                ),

                # Simple plot with different line styles
                Container(
                    Plot([
                            LinePlotElement(
                                [1.0, 4.0, 2.0, 8.0, 5.0, 7.0];  # Just y values
                                color=Vec4{Float32}(0.8, 0.2, 0.0, 1.0),  # Red
                                width=3.0f0,
                                line_style=DOT
                            ),
                            LinePlotElement(
                                [0.5, 3.5, 1.5, 7.5, 4.5, 6.5];  # Offset data
                                color=Vec4{Float32}(0.2, 0.2, 0.8, 1.0),  # Blue
                                width=2.5f0,
                                line_style=DASHDOT
                            )
                        ],
                        PlotStyle(show_grid=true, show_legend=true),
                        plot2_state[],  # Add state management
                        (new_state) -> plot2_state[] = new_state  # Add callback
                    )
                ),
            ], padding=0.0, spacing=0.0)
    end

    Fugl.run(MyApp, title="Line Plot Demo", window_width_px=800, window_height_px=600, fps_overlay=true)
end

main()
