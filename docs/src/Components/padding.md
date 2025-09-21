# Padding

``` @example PaddingExample
using Fugl

function MyApp()
    Container(
        Padding(TextButton("SomeText"), 20.0f0),
        style = ContainerStyle(padding = 0.0f0)
    )
end

screenshot(MyApp, "padding.png", 812, 300);
nothing #hide
```

![Row example](padding.png)
