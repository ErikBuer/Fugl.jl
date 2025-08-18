# Image

``` @example LogoImageExample
using Fugl
using Fugl: Text

function MyApp()
    IntrinsicColumn([
        IntrinsicHeight(Container(Text("Image Component Example"))),
        Container(Image("../assets/julia_logo.png"))
    ])
end

screenshot(MyApp, "logo_image.png", 840, 400);
nothing #hide
```

![Logo Image](logo_image.png)

## Missing Image Example

When an image path is empty or the file doesn't exist, a placeholder is shown:

``` @example MissingImageExample
using Fugl

function MyApp()
    Container(Image(""))
end

screenshot(MyApp, "missing_image.png", 840, 300);
nothing #hide
```

![Missing Image](missing_image.png)
