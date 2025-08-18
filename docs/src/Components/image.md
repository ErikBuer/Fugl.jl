# Image

``` @example MissingImageExample
using Fugl

function MyApp()
    Container(Image(""))
end

screenshot(MyApp, "missing_image.png", 840, 300);
nothing #hide
```

![Image component](missing_image.png)
