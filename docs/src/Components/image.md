# Image

``` @example LogoImageExample
using Fugl
using Fugl: Text

function MyApp()
    IntrinsicColumn([
        IntrinsicHeight(Container(Text("Image Component Example"))),
        Container(Image("../assets/julia_logo.png"))
    ], spacing=0.0, padding = 0.0)
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
    IntrinsicColumn([
        IntrinsicHeight(Container(Text("Intrinsic Size - Original Dimensions"))),
        Container(
            IntrinsicSize(Image("../assets/julia_logo.png"))
        )
    ], spacing=0.0, padding = 0.0)
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
    IntrinsicColumn([
        IntrinsicHeight(Container(Text("Fixed Size Examples"))),
        Row([
            IntrinsicColumn([
                IntrinsicHeight(Container(Text("100x100"))),
                Container(FixedSize(Image("../assets/julia_logo.png"), 100, 100))
            ], spacing=0.0, padding = 0.0),
            IntrinsicColumn([
                IntrinsicHeight(Container(Text("200x100"))),
                Container(FixedSize(Image("../assets/julia_logo.png"), 200, 100))
            ], spacing=0.0, padding = 0.0),
            IntrinsicColumn([
                IntrinsicHeight(Container(Text("150x150"))),
                Container(FixedSize(Image("../assets/julia_logo.png"), 150, 150))
            ], spacing=0.0, padding = 0.0)
        ], spacing=0.0, padding = 0.0)
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
    IntrinsicColumn([
        IntrinsicHeight(Container(Text("Image Alignment Examples"))),
        Row([
            IntrinsicColumn([
                IntrinsicHeight(Container(Text("Top"))),
                Container(
                    AlignVertical(
                        FixedSize(Image("../assets/julia_logo.png"), 80, 80),
                        :top
                    )
                ),
            ], spacing=0.0, padding=0.0),
            IntrinsicColumn([
                IntrinsicHeight(Container(Text("Center"))),
                Container(
                    AlignVertical(
                        FixedSize(Image("../assets/julia_logo.png"), 80, 80),
                        :center
                    )
                )
            ], spacing=0.0, padding=0.0),
            IntrinsicColumn([
                IntrinsicHeight(Container(Text("Bottom"))),
                Container(
                    AlignVertical(
                        FixedSize(Image("../assets/julia_logo.png"), 80, 80),
                        :bottom
                    )
                ),
            ], spacing=0.0, padding=0.0)
        ], spacing=00.0, padding=0.0)
    ], spacing=0.0, padding=0.0)
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
