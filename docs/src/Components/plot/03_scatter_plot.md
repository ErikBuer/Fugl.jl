# Scatter Plot

``` @example ScatterPlotExample
using Fugl
using Fugl: Text, ScatterPlotElement, CIRCLE, TRIANGLE, RECTANGLE

function MyApp()
    # Generate sample data for scatter plot
    x_data = collect(1:10)
    y1_data = rand(10) .* 5 .+ 2  # Random data between 2-7
    y2_data = rand(10) .* 3 .+ 4  # Random data between 4-7
    y3_data = rand(10) .* 4 .+ 1  # Random data between 1-5

    # Create scatter plot elements with different marker types
    elements = [
        ScatterPlotElement(y1_data; x_data=x_data,
                          fill_color=Vec4{Float32}(0.8, 0.2, 0.2, 0.8),
                          border_color=Vec4{Float32}(0.5, 0.1, 0.1, 1.0),
                          marker_size=8.0f0,
                          border_width=2.0f0,
                          marker_type=CIRCLE,
        )
        ScatterPlotElement(y2_data; x_data=x_data,
                          fill_color=Vec4{Float32}(0.2, 0.8, 0.2, 0.8),
                          border_color=Vec4{Float32}(0.1, 0.5, 0.1, 1.0),
                          marker_size=8.0f0,
                          border_width=2.0f0,
                          marker_type=TRIANGLE,
        )
        ScatterPlotElement(y3_data; x_data=x_data,
                          fill_color=Vec4{Float32}(0.2, 0.2, 0.8, 0.8),
                          border_color=Vec4{Float32}(0.1, 0.1, 0.5, 1.0),
                          marker_size=8.0f0,
                          border_width=2.0f0,
                          marker_type=RECTANGLE,
        )
    ]

    IntrinsicColumn([
        IntrinsicHeight(Container(Text("Scatter Plot Example"))),
        Container(
            Plot(
                elements,
                PlotStyle(
                    background_color=Vec4{Float32}(0.98, 0.98, 0.98, 1.0),  # Light background
                    grid_color=Vec4{Float32}(0.85, 0.85, 0.85, 1.0),        # Gray grid
                    axis_color=Vec4{Float32}(0.0, 0.0, 0.0, 1.0),           # Black axes
                    show_grid=true,
                    padding=50.0f0,
                    anti_aliasing_width=1.5f0
                )
            )
        ),
    ], padding=0.0, spacing=0.0)
end

screenshot(MyApp, "scatterPlot.png", 812, 400);
nothing #hide
```

![Scatter Plot](scatterPlot.png)
