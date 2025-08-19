# Row/Column

## Column

`Column` is a component for creating linear layout.

``` @example ColumnExample
using Fugl

function MyApp()
    Container(
        Column([
            Container(),
            Container(),
            Container(),
        ])
    )
end

screenshot(MyApp, "column.png", 812, 300);
nothing #hide
```

![Column example](column.png)

## Row

`Row` is a component for creating linear layout.

Note how we have omitted the vector in the `Row` argument. Either way is fine.

``` @example RowExample
using Fugl

function MyApp()
    Container(
        Row(
            Container(),
            Container(),
            Container(),
        )
    )
end

screenshot(MyApp, "row.png", 812, 300);
nothing #hide
```

![Row example](row.png)

## IntrinsicColumn

``` @example IntrinsicColumnExample
using Fugl
using Fugl: Text

function MyApp()
    Container(
        IntrinsicColumn(
            FixedSize(Container(Text("Clipping width")), 900, 50),
            FixedSize(Container(), 400, 50),
            FixedSize(Container(), 200, 50),
        )
    )
end

screenshot(MyApp, "intrinsic_column.png", 812, 300);
nothing #hide
```

![Intrinsic Column](intrinsic_column.png)

## IntrinsicRow

``` @example IntrinsicColumnExample
using Fugl
using Fugl: Text

function MyApp()
    Container(
        IntrinsicRow(
            FixedSize(Container(Text("Clipping Height")), 50, 812),
            FixedSize(Container(), 50, 400),
            FixedSize(Container(), 50, 200),
        )
    )
end

screenshot(MyApp, "intrinsic_row.png", 812, 300);
nothing #hide
```

![Intrinsic row](intrinsic_row.png)
