# Stem Plot Example

``` @example StemPlotExample
using Fugl
using Fugl: Text, StemPlotElement, CIRCLE, TRIANGLE

function MyApp()
    # Generate sample data for stem plot
    x_data = collect(1:8)
    y1_data = [3.2, 5.1, 2.8, 6.3, 4.7, 3.9, 5.5, 4.2]
    y2_data = [2.1, 3.8, 4.2, 2.9, 5.4, 4.1, 3.6, 4.8]

    # Create stem plot elements
    elements = [
        StemPlotElement(y1_data; x_data=x_data,
                       line_width=3.0f0,
                       marker_size=6.0f0,
                       border_width=1.5f0,
                       marker_type=CIRCLE,
                       baseline=0.0f0,
        )
        StemPlotElement(y2_data; x_data=x_data .+ 0.3,  # Offset x slightly for visibility
                       line_color=Vec4{Float32}(0.3, 0.7, 0.3, 1.0),     # Green stems
                       fill_color=Vec4{Float32}(0.3, 0.8, 0.3, 1.0),     # Green markers
                       border_color=Vec4{Float32}(0.0, 0.3, 0.0, 1.0),   # Dark green border
                       line_width=3.0f0,
                       marker_size=6.0f0,
                       border_width=1.5f0,
                       marker_type=TRIANGLE,
                       baseline=0.0f0,
        )
    ]

    IntrinsicColumn([
        IntrinsicHeight(Container(Text("Stem Plot Example"))),
        Container(
            Plot(
                elements,
                PlotStyle(
                    background_color=Vec4{Float32}(0.95, 0.98, 0.95, 1.0),  # Light green background
                    grid_color=Vec4{Float32}(0.8, 0.9, 0.8, 1.0),           # Light green grid
                    axis_color=Vec4{Float32}(0.0, 0.0, 0.0, 1.0),           # Black axes
                    show_grid=true,
                    show_axes=true,
                    padding_px=50.0f0,
                    anti_aliasing_width=1.5f0
                )
            )
        ),
    ], padding=0.0, spacing=0.0)
end

screenshot(MyApp, "stemPlot.png", 840, 400);
nothing #hide
```

![Stem Plot](stemPlot.png)
