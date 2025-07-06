# Layout

## Column

`Column` is a component for creating linear layout.

``` @example ColumnExample
using Element

function MyApp()
    Column([
        Container(),
        Container(),
        Container(),
    ])
end

screenshot(MyApp, "column.png", 400, 300);
nothing #hide
```

![Column example](column.png)

## Row

`Row` is a component for creating linear layout.

``` @example RowExample
using Element

function MyApp()
    Row([
        Container(),
        Container(),
        Container(),
    ])
end

screenshot(MyApp, "row.png", 400, 300);
nothing #hide
```

![Row example](row.png)

## Sizing

``` @example IntrinsicSizeExample
using Element

function MyApp()
    Column([
        IntrinsicWidth(Container(Text("IntrinsicWidth"))),
        IntrinsicSize(Container(Text("IntrinsicSize"))),
        IntrinsicHeight(Container(Text("IntrinsicHeight"))),
    ])
end

screenshot(MyApp, "intrinsic_sizing.png", 400, 300);
nothing #hide
```

![Intrinsic sizing example](intrinsic_sizing.png)
