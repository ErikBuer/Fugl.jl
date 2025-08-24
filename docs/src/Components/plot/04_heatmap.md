# Heatmap

``` @example HeatmapExample
using Fugl
using Fugl: Text, HeatmapElement

function MyApp()
    # Create test image data - 2D Gaussian pattern with waves
    size_x, size_y = 30, 30
    data = Matrix{Float32}(undef, size_y, size_x)
    center_x, center_y = size_x / 2, size_y / 2

    for j in 1:size_y
        for i in 1:size_x
            # Distance from center
            dx = i - center_x
            dy = j - center_y
            distance_sq = dx^2 + dy^2

            # Gaussian pattern
            data[j, i] = exp(-distance_sq / (2 * (size_x / 6)^2))
            
            # Add sinusoidal pattern
            wave = 0.3 * sin(i * 0.3) * cos(j * 0.3)
            data[j, i] += wave

            # Add some noise
            data[j, i] += 0.1 * (rand() - 0.5)
        end
    end

    # Create heatmap element with viridis colormap
    elements = [
        HeatmapElement(
            data;
            x_range=(0.0, 10.0),
            y_range=(0.0, 10.0),
            colormap=:viridis,
        )
    ]

    Card(
        "Heatmap Example",
        Plot(
            elements,
            PlotStyle(
                background_color=Vec4{Float32}(0.95, 0.95, 0.95, 1.0),  # Light background
                grid_color=Vec4{Float32}(0.8, 0.8, 0.8, 1.0),           # Gray grid
                axis_color=Vec4{Float32}(0.0, 0.0, 0.0, 1.0),           # Black axes
                show_grid=true,
                padding=50.0f0
            )
        )
    )
end

screenshot(MyApp, "heatmap.png", 812, 400);
nothing #hide
```

![Heatmap](heatmap.png)

## Available Colormaps

The `HeatmapElement` supports several built-in colormaps:

- `:viridis` - Perceptually uniform colormap (purple to yellow)
- `:plasma` - High contrast colormap (purple to pink to yellow)  
- `:hot` - Classic hot colormap (black to red to yellow to white)
- `:grayscale` - Simple grayscale mapping

You can specify the colormap when creating a `HeatmapElement`:

```julia
HeatmapElement(data; colormap=:viridis)  # Default
HeatmapElement(data; colormap=:plasma)   # High contrast
HeatmapElement(data; colormap=:hot)      # Classic hot colors
HeatmapElement(data; colormap=:grayscale) # Grayscale
```

## NaN Value Handling

All colormaps support proper NaN value handling. You can specify a custom color for NaN values using the `nan_color` parameter:

```julia
HeatmapElement(data; 
    colormap=:viridis,
    nan_color=(1.0, 0.0, 1.0, 1.0)  # Magenta for NaN values
)
```

NaN values in the data will be displayed in the specified `nan_color` regardless of which colormap is used, while valid data points will be colored according to the chosen colormap.

## Multiple Colormaps Example

``` @example MultipleColormapsExample
using Fugl
using Fugl: Text, HeatmapElement

function MyApp()
    # Create simple test data - radial pattern
    size_x, size_y = 20, 20
    data = Matrix{Float32}(undef, size_y, size_x)
    
    for j in 1:size_y
        for i in 1:size_x
            # Create radial pattern
            x_norm = (i - size_x/2) / (size_x/2)
            y_norm = (j - size_y/2) / (size_y/2)
            radius = sqrt(x_norm^2 + y_norm^2)
            data[j, i] = max(0.0f0, 1.0f0 - radius)
        end
    end

    # Create heatmap elements with different colormaps
    elements = [
        HeatmapElement(
            data;
            x_range=(0.0, 5.0),
            y_range=(0.0, 5.0),
            colormap=:viridis,
        ),
        HeatmapElement(
            data;
            x_range=(6.0, 11.0),
            y_range=(0.0, 5.0),
            colormap=:plasma,
        ),
        HeatmapElement(
            data;
            x_range=(0.0, 5.0),
            y_range=(6.0, 11.0),
            colormap=:hot,
        ),
        HeatmapElement(
            data;
            x_range=(6.0, 11.0),
            y_range=(6.0, 11.0),
            colormap=:grayscale,
        )
    ]

    Card(
        "Multiple Colormaps Example",
        Plot(
            elements,
            PlotStyle(
                background_color=Vec4{Float32}(0.98, 0.98, 0.98, 1.0),  # Light background
                grid_color=Vec4{Float32}(0.5, 0.5, 0.5, 1.0),           # Gray grid
                axis_color=Vec4{Float32}(0.0, 0.0, 0.0, 1.0),           # Black axes
                show_grid=true,
                padding=50.0f0
            )
        )
    )
end

screenshot(MyApp, "multipleColormaps.png", 812, 400);
nothing #hide
```

![Multiple Colormaps](multipleColormaps.png)

## NaN Values Example

The API support custom colors for NaN-values.

``` @example NaNExample
using Fugl
using Fugl: Text, HeatmapElement

function MyApp()
    # Create data with NaN values
    size_x, size_y = 15, 15
    data = Matrix{Float32}(undef, size_y, size_x)
    
    for j in 1:size_y
        for i in 1:size_x
            # Create pattern with some NaN regions
            x_norm = (i - size_x/2) / (size_x/2)
            y_norm = (j - size_y/2) / (size_y/2)
            
            if abs(x_norm) < 0.3 && abs(y_norm) < 0.3
                data[j, i] = NaN32  # NaN in center region
            else
                data[j, i] = x_norm^2 + y_norm^2
            end
        end
    end

    elements = [
        HeatmapElement(
            data;
            x_range=(0.0, 10.0),
            y_range=(0.0, 10.0),
            colormap=:viridis,
            nan_color=(1.0, 0.0, 1.0, 1.0)  # Magenta for NaN
        )
    ]

    IntrinsicColumn([
        IntrinsicHeight(Container(Text("NaN Values Example"))),
        Plot(
            elements,
            PlotStyle(
                show_grid=true,
                padding=50.0f0
            )
        )
    ], padding=0.0, spacing=0.0)
end

screenshot(MyApp, "nanValues.png", 812, 400);
nothing #hide
```

![NaN Values](nanValues.png)

## Grayscale NaN Example

You can also have a colored NaN cell in grayscale plots.

``` @example GrayscaleNaNExample
using Fugl
using Fugl: Text, HeatmapElement

function MyApp()
    # Create grayscale data with NaN cross pattern
    size_x, size_y = 12, 12
    data = Matrix{Float32}(undef, size_y, size_x)
    
    for j in 1:size_y
        for i in 1:size_x
            # Create NaN cross pattern in the middle
            if i == 6 || j == 6
                data[j, i] = NaN32
            else
                # Create simple gradient
                data[j, i] = Float32((i + j) / (size_x + size_y))
            end
        end
    end

    elements = [
        HeatmapElement(
            data;
            x_range=(0.0, 10.0),
            y_range=(0.0, 10.0),
            colormap=:grayscale,
            nan_color=(1.0, 0.0, 1.0, 1.0)  # Magenta for NaN
        )
    ]

    IntrinsicColumn([
        IntrinsicHeight(Container(Text("Grayscale with NaN Cross"))),
        Plot(
            elements,
            PlotStyle(
                show_grid=true,
                padding=50.0f0
            )
        )
    ], padding=0.0, spacing=0.0)
end

screenshot(MyApp, "grayscaleNaN.png", 812, 400);
nothing #hide
```

![Grayscale NaN](grayscaleNaN.png)

## Checkerboard Example

``` @example CheckerboardExample
using Fugl
using Fugl: Text, HeatmapElement

function MyApp()
    # Create checkerboard pattern
    size_x, size_y = 20, 20
    data = Float32[mod(i+j, 2) == 0 ? 1.0 : 0.0 for i in 1:size_y, j in 1:size_x]

    elements = [
        HeatmapElement(
            data;
            x_range=(0.0, 10.0),
            y_range=(0.0, 10.0),
            colormap=:hot,
        )
    ]

    IntrinsicColumn([
        IntrinsicHeight(Container(Text("Checkerboard Example"))),
        Plot(
            elements,
            PlotStyle(
                show_grid=true,
                padding=50.0f0
            )
        )
    ], padding=0.0, spacing=0.0)
end

screenshot(MyApp, "checkerboard.png", 812, 400);
nothing #hide
```

![Checkerboard](checkerboard.png)

## No Axes Example

``` @example NoAxesExample
using Fugl
using Fugl: Text, HeatmapElement

function MyApp()
    # Create spiral pattern
    size_x, size_y = 25, 25
    data = Matrix{Float32}(undef, size_y, size_x)
    
    for j in 1:size_y
        for i in 1:size_x
            x_norm = (i - size_x/2) / (size_x/2)
            y_norm = (j - size_y/2) / (size_y/2)
            angle = atan(y_norm, x_norm)
            radius = sqrt(x_norm^2 + y_norm^2)
            data[j, i] = sin(angle * 3 + radius * 8) * exp(-radius)
        end
    end

    elements = [
        HeatmapElement(
            data;
            x_range=(0.0, 10.0),
            y_range=(0.0, 10.0),
            colormap=:plasma,
        )
    ]

    IntrinsicColumn([
        IntrinsicHeight(Container(Text("No Axes Example"))),
        Plot(
            elements,
            PlotStyle(
                show_grid=false,
                show_left_axis=false,
                show_right_axis=false,
                show_top_axis=false,
                show_bottom_axis=false,
                show_x_tick_marks=false,
                show_y_tick_marks=false,
                show_x_tick_labels=false,
                show_y_tick_labels=false,
                padding=10.0f0
            )
        )
    ], padding=0.0, spacing=0.0)
end

screenshot(MyApp, "noAxes.png", 812, 400);
nothing #hide
```

![No Axes](noAxes.png)
