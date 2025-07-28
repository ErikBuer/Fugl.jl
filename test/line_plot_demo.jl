using Fugl

function main()
    # Simple streaming data simulation
    time_data = Ref(collect(0.0:0.1:10.0))
    y_data = Ref(sin.(time_data[]))

    # For real-time updates
    frame_count = Ref(0)

    function MyApp()
        # Update data every few frames (simulate streaming)
        frame_count[] += 1
        if frame_count[] % 10 == 0  # Update every 10 frames
            # Add new data point
            new_time = time_data[][end] + 0.1
            new_y = sin(new_time)

            # Keep only last 100 points (rolling window)
            if length(time_data[]) >= 100
                time_data[] = [time_data[][2:end]; new_time]
                y_data[] = [y_data[][2:end]; new_y]
            else
                time_data[] = [time_data[]; new_time]
                y_data[] = [y_data[]; new_y]
            end
        end

        IntrinsicColumn([
            IntrinsicHeight(Container(Text("Real-time Line Plot Demo"))),

            # Line plot with both x and y data
            Container(
                LinePlot(
                    y_data[];
                    x_data=time_data[],
                    style=LinePlotStyle(
                        line_color=Vec4{Float32}(0.0, 0.8, 0.2, 1.0),  # Green
                        line_width=3.0f0,
                        show_grid=true
                    )
                )
            ),

            # Simple plot with auto-generated x values (1, 2, 3, ...)
            Container(
                LinePlot(
                    [1.0, 4.0, 2.0, 8.0, 5.0, 7.0];  # Just y values
                    style=LinePlotStyle(
                        line_color=Vec4{Float32}(0.8, 0.2, 0.0, 1.0),  # Red
                        line_width=2.0f0
                    )
                )
            ), IntrinsicHeight(Container(Text("Points: $(length(y_data[]))"))),
            IntrinsicHeight(Container(Text("Latest: $(round(y_data[][end], digits=3))"))),
        ])
    end

    Fugl.run(MyApp, title="Line Plot Demo", window_width_px=800, window_height_px=600)
end

main()
