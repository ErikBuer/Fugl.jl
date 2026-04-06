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

screenshot(MyApp, "intrinsic_sizing.png", 812, 300);
nothing #hide
```

![Intrinsic sizing example](intrinsic_sizing.png)

``` @example FixedSizeExample
using Fugl
using Fugl: Text

function MyApp()
    Container(
        Column(
            FixedSize(Container(), 812, 50),
            FixedSize(Container(), 812, 50),
            FixedSize(Container(), 812, 50),
        )
    )
end

screenshot(MyApp, "fixed_sizing.png", 812, 300);
nothing #hide
```

![Fixed sizing example](fixed_sizing.png)

## Flexible Sizing

The flexible sizing components force their wrapped components to consume all available space from their parent, regardless of the child's intrinsic size preferences. These are useful when you want a component to fill remaining space in layouts.

``` @example FlexibleSizeExample
using Fugl
using Fugl: Text

function MyApp()
    Container(
        Row(
            # IntrinsicWidth only takes what it needs
            IntrinsicWidth(Container(Text("Intrinsic"))),
            # FlexibleWidth consumes all remaining space
            FlexibleWidth(Container(Text("Flexible fills remaining space"))),
        )
    )
end

screenshot(MyApp, "flexible_width_comparison.png", 812, 100);
nothing #hide
```

![Flexible width comparison](flexible_width_comparison.png)

``` @example FlexibleHeightExample
using Fugl
using Fugl: Text

function MyApp()
    Container(
        Column(
            # IntrinsicHeight only takes what it needs
            IntrinsicHeight(Container(Text("Intrinsic"))),
            # FlexibleHeight consumes all remaining space
            FlexibleHeight(Container(Text("Flexible\nfills\nremaining\nspace"))),
        )
    )
end

screenshot(MyApp, "flexible_height_comparison.png", 812, 300);
nothing #hide
```

![Flexible height comparison](flexible_height_comparison.png)

``` @example FlexibleSizeExample
using Fugl
using Fugl: Text

function MyApp()
    Container(
        Column(
            Text("FlexibleSize fills all available space:"),
            FlexibleSize(Container(Text("Flexible Size"))),
        )
    )
end

screenshot(MyApp, "flexible_size.png", 812, 300);  
nothing #hide
```

![Flexible size example](flexible_size.png)
