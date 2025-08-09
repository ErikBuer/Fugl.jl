# Plot

``` @example PlotExample
using Fugl
using Fugl: Text, LinePlotElement, SOLID, DASH, DOT

function MyApp()
    # Generate sample data for demonstration
    x_data = collect(0.0:0.1:10.0)
    y1_data = sin.(x_data)
    y2_data = cos.(x_data)
    y3_data = sin.(x_data .* 2) .* 0.5

    # Create multiple plot elements with different colors and styles
    elements = [
        LinePlotElement(y1_data; x_data=x_data,
            color=Vec4{Float32}(0.2, 0.6, 0.8, 1.0),
            width=3.0f0,
            line_style=SOLID,
            label="sin(x)"),
        LinePlotElement(y2_data; x_data=x_data,
            color=Vec4{Float32}(0.8, 0.2, 0.2, 1.0),
            width=2.5f0,
            line_style=DASH,
            label="cos(x)"),
        LinePlotElement(y3_data; x_data=x_data,
            color=Vec4{Float32}(0.2, 0.8, 0.2, 1.0),
            width=2.0f0,
            line_style=DOT,
            label="0.5*sin(2x)")
    ]

    IntrinsicColumn([
            IntrinsicHeight(Container(Text("Plot Example"))),
            Container(
                Plot(
                    elements,
                    PlotStyle(
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

## Scatter Plot Example

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
                          label="Dataset A"),
        ScatterPlotElement(y2_data; x_data=x_data,
                          fill_color=Vec4{Float32}(0.2, 0.8, 0.2, 0.8),
                          border_color=Vec4{Float32}(0.1, 0.5, 0.1, 1.0),
                          marker_size=8.0f0,
                          border_width=2.0f0,
                          marker_type=TRIANGLE,
                          label="Dataset B"),
        ScatterPlotElement(y3_data; x_data=x_data,
                          fill_color=Vec4{Float32}(0.2, 0.2, 0.8, 0.8),
                          border_color=Vec4{Float32}(0.1, 0.1, 0.5, 1.0),
                          marker_size=8.0f0,
                          border_width=2.0f0,
                          marker_type=RECTANGLE,
                          label="Dataset C")
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
                    show_axes=true,
                    padding_px=50.0f0,
                    anti_aliasing_width=1.5f0
                )
            )
        ),
    ], padding=0.0, spacing=0.0)
end

screenshot(MyApp, "scatterPlot.png", 600, 400);
nothing #hide
```

![Scatter Plot](scatterPlot.png)

## Stem Plot Example

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
                       label="Series A"),
        StemPlotElement(y2_data; x_data=x_data .+ 0.3,  # Offset x slightly for visibility
                       line_color=Vec4{Float32}(0.3, 0.7, 0.3, 1.0),     # Green stems
                       fill_color=Vec4{Float32}(0.3, 0.8, 0.3, 1.0),     # Green markers
                       border_color=Vec4{Float32}(0.0, 0.3, 0.0, 1.0),   # Dark green border
                       line_width=3.0f0,
                       marker_size=6.0f0,
                       border_width=1.5f0,
                       marker_type=TRIANGLE,
                       baseline=0.0f0,
                       label="Series B")
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

screenshot(MyApp, "stemPlot.png", 600, 400);
nothing #hide
```

![Stem Plot](stemPlot.png)
