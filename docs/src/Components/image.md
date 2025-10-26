# Image

## Image from file

``` @example LogoImageExample
using Fugl

function MyApp()
    Card(
        "Image", title_align=:center,
        Image("../assets/julia_logo.png")
    )
end

screenshot(MyApp, "logo_image.png", 812, 400);
nothing #hide
```

![Logo Image](logo_image.png)

## Image from matrix

You can also load matrixes as images.

``` @example MatrixImageExample
using Fugl
using ColorTypes
using FixedPointNumbers

size_x, size_y = 256, 256

rgba_matrix = Matrix{RGBA{N0f8}}(undef, size_y, size_x)
center_x, center_y = size_x / 2, size_y / 2

for j in 1:size_y
    for i in 1:size_x
        # Normalized coordinates from -1 to 1
        x = (i - center_x) / (size_x / 2)
        y = (j - center_y) / (size_y / 2)
        
        # Distance from center
        r = sqrt(x^2 + y^2)
        
        # Angle for radial patterns
        θ = atan(y, x)
        
        # Create a smooth radial gradient with subtle spiral pattern
        intensity = exp(-r^2 / 0.8) * (1 + 0.3 * sin(6 * θ + 2 * r))
        intensity = clamp(intensity, 0.0, 1.0)
        
        # Create appealing color gradients
        red = intensity * 0.8 + 0.1
        green = intensity * 0.4 + 0.2 * sin(4 * θ)
        blue = intensity * 0.9 + 0.1 * cos(8 * θ)
        
        # Clamp and convert to N0f8
        red = clamp(red, 0.0, 1.0)
        green = clamp(green, 0.0, 1.0)  
        blue = clamp(blue, 0.0, 1.0)
        
        rgba_matrix[j, i] = RGBA{N0f8}(red, green, blue, 1.0)
    end
end

function MyApp()
    Card(
        "Image", title_align=:center,
        Image(rgba_matrix)
    )
end

screenshot(MyApp, "matrix_image.png", 812, 400);
nothing #hide
```

![Matrix as image](matrix_image.png)

## Intrinsic Size Example

Images naturally use their intrinsic size (original dimensions). You can wrap them in `IntrinsicSize` to ensure they maintain their natural proportions:

``` @example IntrinsicSizeExample
using Fugl
using Fugl: Text

function MyApp()
    Card(
        "Intrinsic Size - Original Dimensions", title_align=:center,
        IntrinsicSize(Image("../assets/julia_logo.png"))
    )
end

screenshot(MyApp, "intrinsic_image.png", 812, 400);
nothing #hide
```

![Intrinsic Size Image](intrinsic_image.png)

## Fixed Size Example

You can control the exact size of images using `FixedSize`. The image will scale proportionally to fit within the specified dimensions:

``` @example FixedSizeExample
using Fugl
using Fugl: Text

function MyApp()
    Row([
        Card(
            "100x100", title_align=:center,
            FixedSize(Image("../assets/julia_logo.png"), 100, 100)
        ),
        Card(
            "200x100", title_align=:center,
            FixedSize(Image("../assets/julia_logo.png"), 200, 100)
        ),
        Card(
            "150x150", title_align=:center,
            FixedSize(Image("../assets/julia_logo.png"), 150, 150)
        )
    ], spacing=0.0, padding = 0.0)
end

screenshot(MyApp, "fixed_size_images.png", 812, 400);
nothing #hide
```

![Fixed Size Images](fixed_size_images.png)

## Alignment Example

You can control how images are aligned within their containers using `AlignVertical` and `AlignHorizontal`:

``` @example AlignmentExample
using Fugl
using Fugl: Text

function MyApp()
    Row([
        Card(
            "Top", title_align=:center,
            AlignVertical(
                FixedSize(Image("../assets/julia_logo.png"), 80, 80),
                :top
            )

        ),
        Card(
            "Middle", title_align=:center,
            AlignVertical(
                FixedSize(Image("../assets/julia_logo.png"), 80, 80),
                :middle
            )
        ),
        Card(
            "Bottom", title_align=:center,
            AlignVertical(
                FixedSize(Image("../assets/julia_logo.png"), 80, 80),
                :bottom
            )
        )
    ], spacing=00.0, padding=0.0)
end

screenshot(MyApp, "aligned_images.png", 812, 400);
nothing #hide
```

![Aligned Images](aligned_images.png)

## Missing Image Example

When an image path is empty or the file doesn't exist, a placeholder is shown:

``` @example MissingImageExample
using Fugl

function MyApp()
    Container(Image(""))
end

screenshot(MyApp, "missing_image.png", 812, 300);
nothing #hide
```

![Missing Image](missing_image.png)
