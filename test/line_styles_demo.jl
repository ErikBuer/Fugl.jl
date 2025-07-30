using Fugl
using Fugl: Text, SOLID, DASH, DOT, DASHDOT

function main()
    # Demo showcasing different line styles, grid, and axes
    time_data = collect(0.0:0.1:10.0)

    # Create different traces with different line styles
    sin_trace = LinePlotTrace(
        sin.(time_data);
        x_data=time_data,
        color=Vec4{Float32}(1.0, 0.2, 0.2, 1.0),  # Red
        width=3.0f0,
        line_style=SOLID,
        label="Sine (Solid)"
    )

    cos_trace = LinePlotTrace(
        cos.(time_data);
        x_data=time_data,
        color=Vec4{Float32}(0.2, 0.8, 0.2, 1.0),  # Green
        width=3.0f0,
        line_style=DASH,
        label="Cosine (Dash)"
    )

    tan_trace = LinePlotTrace(
        0.5 * tan.(time_data * 0.3);
        x_data=time_data,
        color=Vec4{Float32}(0.2, 0.2, 1.0, 1.0),  # Blue
        width=2.5f0,
        line_style=DOT,
        label="Tan/2 (Dot)"
    )

    exp_trace = LinePlotTrace(
        0.1 * exp.(time_data * 0.2) .- 0.5;
        x_data=time_data,
        color=Vec4{Float32}(0.8, 0.4, 0.8, 1.0),  # Purple
        width=2.0f0,
        line_style=DASHDOT,
        label="Exp (DashDot)"
    )

    function MyApp()
        IntrinsicColumn([
            IntrinsicHeight(Container(Text("Line Styles Demo - Grid & Axes Test"))),

            # Multi-trace plot with grid and axes enabled
            Container(
                LinePlot(
                    [sin_trace, cos_trace, tan_trace, exp_trace];
                    style=LinePlotStyle(
                        background_color=Vec4{Float32}(0.98, 0.98, 0.98, 1.0),  # Light gray background
                        grid_color=Vec4{Float32}(0.85, 0.85, 0.85, 1.0),        # Gray grid
                        axis_color=Vec4{Float32}(0.0, 0.0, 0.0, 1.0),           # Black axes
                        padding_px=20.0f0,
                        show_grid=true,
                        show_axes=true
                    )
                )
            ), IntrinsicHeight(Container(Text("Legend:"))),
            IntrinsicHeight(Container(Text("Red Solid: sin(x)"))),
            IntrinsicHeight(Container(Text("Green Dash: cos(x)"))),
            IntrinsicHeight(Container(Text("Blue Dot: tan(x)/2"))),
            IntrinsicHeight(Container(Text("Purple DashDot: exp(x/5) - 0.5"))),
        ])
    end

    Fugl.run(MyApp, title="Line Styles Demo", window_width_px=1000, window_height_px=700, debug_overlay=true)
end

main()
