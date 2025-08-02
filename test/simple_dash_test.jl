using Fugl
using Fugl: Text, DASH

function main()
    # Simple test of dashed line with grid and axes
    time_data = Ref(collect(0.0:0.1:6.0))
    y_data = Ref(sin.(time_data[]))

    function MyApp()
        IntrinsicColumn([
            IntrinsicHeight(Container(Text("Dashed Line with Grid Test"))),

            # Single trace with dashed line style (as vector)
            Container(
                LinePlot(
                    [LinePlotTrace(
                        y_data[];
                        x_data=time_data[],
                        color=Vec4{Float32}(1.0, 0.2, 0.2, 1.0),
                        width=3.0f0,
                        line_style=DASH,
                        label="Dashed Sine"
                    )];
                    style=LinePlotStyle(
                        background_color=Vec4{Float32}(0.95, 0.95, 0.95, 1.0),
                        grid_color=Vec4{Float32}(0.8, 0.8, 0.8, 1.0),
                        axis_color=Vec4{Float32}(0.0, 0.0, 0.0, 1.0),
                        padding_px=15.0f0,
                        show_grid=true,
                        show_axes=true
                    )
                )
            ), IntrinsicHeight(Container(Text("Red dashed line: sin(x)"))),
            IntrinsicHeight(Container(Text("Grid and axes should be visible"))),
        ])
    end

    Fugl.run(MyApp, title="Dashed Line Test", window_width_px=800, window_height_px=600, fps_overlay=true)
end

main()
