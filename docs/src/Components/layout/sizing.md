# Sizing

``` @example IntrinsicSizeExample
using Fugl
using Fugl: Text

function MyApp()
    Container(
        Column(
            IntrinsicWidth(Container(Text("IntrinsicWidth"))),
            IntrinsicSize(Container(Text("IntrinsicSize"))),
            IntrinsicHeight(Container(Text("IntrinsicHeight"))),
        )
    )
end

screenshot(MyApp, "intrinsic_sizing.png", 840, 300);
nothing #hide
```

![Intrinsic sizing example](intrinsic_sizing.png)

``` @example FixedSizeExample
using Fugl
using Fugl: Text

function MyApp()
    Container(
        Column(
            FixedSize(Container(), 840, 50),
            FixedSize(Container(), 840, 50),
            FixedSize(Container(), 840, 50),
        )
    )
end

screenshot(MyApp, "fixed_sizing.png", 840, 300);
nothing #hide
```

![Fixed sizing example](fixed_sizing.png)