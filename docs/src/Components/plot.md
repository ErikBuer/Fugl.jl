# Plot

``` @example PlotExample
using Fugl
using Fugl: Text

function MyApp()
    # Generate sample data for demonstration
    x_data = collect(0.0:0.1:10.0)
    y1_data = sin.(x_data)
    y2_data = cos.(x_data)
    y3_data = sin.(x_data .* 2) .* 0.5

    # Create multiple traces with different colors and styles
    traces = [
        LinePlotTrace(y1_data; x_data=x_data, 
                     color=Vec4{Float32}(0.2, 0.6, 0.8, 1.0), 
                     width=3.0f0, 
                     line_style=SOLID,
                     label="sin(x)"),
        LinePlotTrace(y2_data; x_data=x_data, 
                     color=Vec4{Float32}(0.8, 0.2, 0.2, 1.0), 
                     width=2.5f0, 
                     line_style=DASH,
                     label="cos(x)"),
        LinePlotTrace(y3_data; x_data=x_data, 
                     color=Vec4{Float32}(0.2, 0.8, 0.2, 1.0), 
                     width=2.0f0, 
                     line_style=DOT,
                     label="0.5*sin(2x)")
    ]

    IntrinsicColumn([
        IntrinsicHeight(Container(Text("Plot Example"))),
        Container(
            LinePlot(
                traces;
                style=LinePlotStyle(
                    background_color=Vec4{Float32}(0.3, 0.3, 0.3, 1.0),  # Gray background
                    grid_color=Vec4{Float32}(0.9, 0.9, 0.9, 1.0),        # Light gray grid
                    axis_color=Vec4{Float32}(1.0, 1.0, 1.0, 1.0),        # White axes
                    show_grid=true,
                    show_axes=true,
                    padding_px=50.0f0
                )
            )
        ),
    ], padding=0.0, spacing=0.0)
end

screenshot(MyApp, "linePlot.png", 600, 400);
nothing #hide
```

![Line Plot](linePlot.png)
