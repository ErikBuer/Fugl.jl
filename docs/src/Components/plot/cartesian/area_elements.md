# Area Elements

`XAreaElement` and `YAreaElement` are decorative plot elements that fill a colored band across
the full visible range of the opposing axis. They are useful for highlighting regions such as
frequency bands, time windows, or value tolerance zones.

Place area elements **before** data elements in the vector so they render behind the lines and markers.
Area elements do not affect auto-scaling.

## X Area (vertical band)

`XAreaElement` draws a vertical band between two X data-space values, spanning the full visible Y range.

``` @example AreaExample
using Fugl
using Fugl: Text, LinePlotElement, XAreaElement, SOLID

function MyApp()
    x = collect(0.0:0.1:10.0)
    y = sin.(x)

    elements = [
        XAreaElement(2.0, 4.0;
            color=Vec4f(0.3, 0.7, 1.0, 0.18),
            label="Region A"
        ),
        XAreaElement(7.0, 9.0;
            color=Vec4f(1.0, 0.4, 0.3, 0.18),
            label="Region B"
        ),
        LinePlotElement(y; x_data=x,
            color=Vec4f(0.4, 0.8, 0.5, 1.0),
            width=2.5f0,
            line_style=SOLID,
            label="Signal"
        ),
    ]

    Card(
        "X Area Elements",
        Plot(
            elements,
            PlotStyle(
                background_color=Vec4f(0.08, 0.10, 0.14, 1.0),
                grid_color=Vec4f(0.25, 0.25, 0.30, 1.0),
                axis_color=Vec4f(0.9, 0.9, 0.95, 1.0),
                show_grid=true,
                padding=54.0f0,
            )
        ),
        style=ContainerStyle(
            background_color=Vec4f(0.15, 0.15, 0.18, 1.0),
            border_color=Vec4f(0.25, 0.25, 0.30, 1.0),
            border_width=1.5f0,
            padding=12.0f0,
            corner_radius=6.0f0
        ),
        title_style=TextStyle(size_points=16, color=Vec4f(0.9, 0.9, 0.95, 1.0))
    )
end

screenshot(MyApp, "x_area_element.png", 812, 380);
nothing #hide
```

![X Area Element](x_area_element.png)

## Y Area (horizontal band)

`YAreaElement` draws a horizontal band between two Y data-space values, spanning the full visible X range.

``` @example AreaExample
using Fugl: Text, LinePlotElement, YAreaElement, SOLID

function MyApp()
    x = collect(0.0:0.1:10.0)
    y = sin.(x)

    elements = [
        YAreaElement(-1.0, -0.5;
            color=Vec4f(1.0, 0.4, 0.3, 0.18),
            label="Low zone"
        ),
        YAreaElement(0.5, 1.0;
            color=Vec4f(0.3, 0.8, 0.4, 0.18),
            label="High zone"
        ),
        LinePlotElement(y; x_data=x,
            color=Vec4f(0.4, 0.6, 0.9, 1.0),
            width=2.5f0,
            line_style=SOLID,
            label="Signal"
        ),
    ]

    Card(
        "Y Area Elements",
        Plot(
            elements,
            PlotStyle(
                background_color=Vec4f(0.08, 0.10, 0.14, 1.0),
                grid_color=Vec4f(0.25, 0.25, 0.30, 1.0),
                axis_color=Vec4f(0.9, 0.9, 0.95, 1.0),
                show_grid=true,
                padding=54.0f0,
            )
        ),
        style=ContainerStyle(
            background_color=Vec4f(0.15, 0.15, 0.18, 1.0),
            border_color=Vec4f(0.25, 0.25, 0.30, 1.0),
            border_width=1.5f0,
            padding=12.0f0,
            corner_radius=6.0f0
        ),
        title_style=TextStyle(size_points=16, color=Vec4f(0.9, 0.9, 0.95, 1.0))
    )
end

screenshot(MyApp, "y_area_element.png", 812, 380);
nothing #hide
```

![Y Area Element](y_area_element.png)
