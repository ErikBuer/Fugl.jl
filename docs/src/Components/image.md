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
my_matrix = Matrix{Float32}(undef, size_y, size_x)
center_x, center_y = size_x / 2, size_y / 2

for j in 1:size_y
    for i in 1:size_x
        # Distance from center
        dx = i - center_x
        dy = j - center_y
        distance_sq = dx^2 + dy^2

        # Gaussian pattern
        my_matrix[j, i] = exp(-distance_sq / (2 * (size_x / 6)^2))
        
        # Add sinusoidal pattern
        wave = 0.3 * sin(i * 0.3) * cos(j * 0.3)
        my_matrix[j, i] += wave

        # Add some noise
        my_matrix[j, i] += 0.1 * (rand() - 0.5)
    end
end

# Clamp values to [0, 1] for N0f8 conversion
clamped_matrix = clamp.(my_matrix, 0.0f0, 1.0f0)
rgba_matrix = RGBA{N0f8}.(clamped_matrix, 0.5.*(1.0.-clamped_matrix), clamped_matrix, N0f8(1.0))

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
