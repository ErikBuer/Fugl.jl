using Fugl
using Fugl: Text, LinePlotTrace

function main()
    # User manages all state - no internal mutation
    time_data = Ref(collect(0.0:0.1:10.0))
    sin_data = Ref(sin.(time_data[]))
    cos_data = Ref(cos.(time_data[]))

    frame_count = Ref(0)

    function MyApp()

        new_time = time_data[][end] + 0.1

        # User manages data - append and limit size themselves
        push!(time_data[], new_time)
        push!(sin_data[], sin(new_time))
        push!(cos_data[], cos(new_time))

        # User controls window size (keep last 200 points)
        max_points = 200
        if length(time_data[]) > max_points
            time_data[] = time_data[][(end-max_points+1):end]
            sin_data[] = sin_data[][(end-max_points+1):end]
            cos_data[] = cos_data[][(end-max_points+1):end]
        end


        # Create fresh traces each frame with current data
        traces = [
            LinePlotTrace(
                sin_data[];
                x_data=time_data[],
                color=Vec4{Float32}(1.0, 0.2, 0.2, 1.0),
                width=3.0f0,
                label="sin(x)"
            ),
            LinePlotTrace(
                cos_data[];
                x_data=time_data[],
                color=Vec4{Float32}(0.2, 1.0, 0.2, 1.0),
                width=2.0f0,
                label="cos(x)"
            )
        ]

        IntrinsicColumn([
            IntrinsicHeight(Container(Text("Multi-Trace Plot - User-Managed State"))),

            # Create fresh plot with current data
            Container(
                LinePlot(
                    traces;
                    style=LinePlotStyle(
                        background_color=Vec4{Float32}(0.2, 0.2, 0.2, 1.0),
                        show_grid=true
                    )
                )
            ), IntrinsicHeight(Container(Text("Frame: $(frame_count[])"))),
            IntrinsicHeight(Container(Text("Data points: $(length(time_data[]))"))),
            IntrinsicHeight(Container(Text("Latest time: $(round(time_data[][end], digits=1))"))),
        ])
    end

    Fugl.run(MyApp, title="User-Managed Multi-Trace Plot", window_width_px=1000, window_height_px=700, fps_overlay=true)
end

main()
