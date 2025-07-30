using Fugl
using Fugl: Text

function main()
    # Simple single trace demo to test basic functionality
    time_data = Ref(collect(0.0:0.1:10.0))
    y_data = Ref(sin.(time_data[]))

    frame_count = Ref(0)

    function MyApp()
        new_time = time_data[][end] + 0.1
        push!(time_data[], new_time)
        push!(y_data[], sin(new_time))

        # Keep last 100 points
        max_points = 100
        if length(time_data[]) > max_points
            time_data[] = time_data[][(end-max_points+1):end]
            y_data[] = y_data[][(end-max_points+1):end]
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
                            line_width=4.0f0,
                            background_color=Vec4{Float32}(0.2, 0.2, 0.2, 1.0),
                            axis_color=Vec4{Float32}(1.0, 1.0, 1.0, 1.0),
                        )
                    )
                ),
            ], padding=0.0, spacing=0.0)
    end

    Fugl.run(MyApp, title="Single Trace Test", window_width_px=800, window_height_px=600, debug_overlay=true)
end

main()
