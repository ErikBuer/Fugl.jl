# Image

``` @example LogoImageExample
using Fugl
using Fugl: Text

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
