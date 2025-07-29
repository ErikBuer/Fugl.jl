using Fugl
using Fugl: Text

function main()
    # Simple single trace demo to test basic functionality
    time_data = Ref(collect(0.0:0.1:10.0))
    y_data = Ref(sin.(time_data[]))

    frame_count = Ref(0)

    function MyApp()
        frame_count[] += 1

        # Update every 20 frames
        if frame_count[] % 20 == 0
            new_time = time_data[][end] + 0.1
            push!(time_data[], new_time)
            push!(y_data[], sin(new_time))

            # Keep last 100 points
            max_points = 100
            if length(time_data[]) > max_points
                time_data[] = time_data[][(end-max_points+1):end]
                y_data[] = y_data[][(end-max_points+1):end]
            end
        end

        IntrinsicColumn([
            IntrinsicHeight(Container(Text("Single Trace Plot Test"))),

            # Single trace using original constructor
            Container(
                LinePlot(
                    y_data[];
                    x_data=time_data[],
                    style=LinePlotStyle(
                        line_color=Vec4{Float32}(1.0, 0.2, 0.2, 1.0),
                        line_width=3.0f0,
                        background_color=Vec4{Float32}(0.95, 0.95, 0.95, 1.0)
                    )
                )
            ), IntrinsicHeight(Container(Text("Frame: $(frame_count[])"))),
            IntrinsicHeight(Container(Text("Points: $(length(y_data[]))"))),
        ])
    end

    Fugl.run(MyApp, title="Single Trace Test", window_width_px=800, window_height_px=600, debug_overlay=true)
end

main()
